//
//  midoriApp.swift
//  midori
//
//  Created by Deepak Patnaik on 06.11.25.
//

import SwiftUI
import AppKit
import ServiceManagement
import AudioToolbox

@main
struct midoriApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var keyMonitor: KeyMonitor?
    var audioRecorder: AudioRecorder?
    var waveformWindow: WaveformWindow?
    var transcriptionManager: TranscriptionManager?
    var appleSpeechManager: AppleSpeechManager?
    var aboutWindow: AboutWindow?

    // Keep strong references to sound objects to prevent deallocation
    var popSound1: NSSound?
    var popSound2: NSSound?

    // Bulletproof state management
    private var isRecording = false
    private var recordingStartTimer: DispatchWorkItem?
    private let stateQueue = DispatchQueue(label: "com.midori.stateQueue")

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✓ Midori launching...")

        // Hide dock icon (LSUIElement handles this, but ensure no window appears)
        NSApp.setActivationPolicy(.accessory)

        // Enable launch at login
        enableLaunchAtLogin()

        // Create menu bar status item
        setupMenuBar()

        // Initialize managers
        audioRecorder = AudioRecorder()
        transcriptionManager = TranscriptionManager()
        appleSpeechManager = AppleSpeechManager()
        waveformWindow = WaveformWindow()
        aboutWindow = AboutWindow()

        // Setup audio recorder callback
        audioRecorder?.onAudioLevelUpdate = { [weak self] level in
            self?.waveformWindow?.updateAudioLevel(level)
        }

        // Initialize key monitor
        keyMonitor = KeyMonitor()
        keyMonitor?.onRightCommandPressed = { [weak self] isPressed in
            self?.handleRightCommandKey(isPressed: isPressed)
        }

        print("✓ Midori ready - Press Right Command to start recording")
    }

    private func enableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.register()
            print("✓ Launch at login enabled")
        } catch {
            print("⚠️ Failed to enable launch at login: \(error.localizedDescription)")
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Midori")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Midori - Voice to Text", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Add About menu item
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))

        // Add launch at login toggle
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "l")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Restart", action: #selector(restart), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func handleRightCommandKey(isPressed: Bool) {
        if isPressed {
            print("🎤 Right Command pressed - Initiating recording...")
            initiateRecording()
        } else {
            print("🔴 Right Command released - Initiating stop...")
            initiateStop()
        }
    }

    private func initiateRecording() {
        stateQueue.async { [weak self] in
            guard let self = self else { return }

            // Cancel any pending start timer from previous presses
            self.recordingStartTimer?.cancel()

            // If already recording, ignore (handles double-tap)
            guard !self.isRecording else {
                print("⚠️ Already recording, ignoring duplicate press")
                return
            }

            print("✓ Recording initiation accepted")

            // Create cancellable timer for the 0.5-second delay
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                // Execute startRecording on the state queue to ensure thread safety
                self.stateQueue.async {
                    self.startRecording()
                }
            }

            self.recordingStartTimer = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }

    private func initiateStop() {
        stateQueue.async { [weak self] in
            guard let self = self else { return }

            // Cancel pending start timer if key released before 0.5 second
            if let timer = self.recordingStartTimer {
                timer.cancel()
                self.recordingStartTimer = nil
                print("⚠️ Key released before 0.5s - Recording cancelled")
                return
            }

            // If not recording, nothing to stop
            guard self.isRecording else {
                print("⚠️ Not recording, ignoring release")
                return
            }

            print("✓ Stop initiation accepted")
            self.stopRecording()
        }
    }

    private func startRecording() {
        // This method is called from within stateQueue.async, so state is already protected
        guard !isRecording else {
            print("⚠️ Already recording in startRecording, aborting")
            return
        }
        isRecording = true
        recordingStartTimer = nil  // Clear the timer reference

        print("✅ Recording started")

        // All UI and audio operations must happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Create sound objects and keep strong references to prevent deallocation
            self.popSound1 = NSSound(named: "Pop")
            self.popSound2 = NSSound(named: "Pop")

            if let sound1 = self.popSound1 {
                sound1.volume = 1.0
                sound1.play()
                print("🔊 Pop sound 1 played")
            } else {
                print("⚠️ Pop sound not available")
            }

            // Play second pop with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                if let sound2 = self?.popSound2 {
                    sound2.volume = 1.0
                    sound2.play()
                    print("🔊 Pop sound 2 played")
                }
            }

            // Show waveform window
            self.waveformWindow?.show()

            // Start audio recording (device configured per-engine, not system-wide)
            self.audioRecorder?.startRecording()
        }
    }

    private func stopRecording() {
        // This method is called from within stateQueue.async, so state is already protected
        guard isRecording else {
            print("⚠️ stopRecording called but wasn't recording")
            return
        }

        isRecording = false
        recordingStartTimer = nil  // Ensure timer is cleared

        print("✅ Recording stopped")

        // All UI and audio operations must happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Stop recording
            self.audioRecorder?.stopRecording()

            // Hide waveform
            self.waveformWindow?.hide()

            // Get audio data and transcribe
            if let audioData = self.audioRecorder?.getAudioData() {
                print("📝 Transcribing audio...")
                print("🔍 TRANSCRIPTION FLOW HIT - audioData size: \(audioData.count) bytes")
                self.appleSpeechManager?.transcribe(audioData: audioData) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let text):
                            print("✓ Transcription complete: [REDACTED - \(text.count) characters]")
                            self?.injectText(text)
                        case .failure(let error):
                            print("❌ Transcription failed: \(error.localizedDescription)")
                            // Silent failure - no dialog box, just log it
                        }
                    }
                }
            } else {
                print("⚠️ No audio data captured")
            }
        }
    }

    private func injectText(_ text: String) {
        // Check accessibility permissions
        let trusted = AXIsProcessTrusted()

        if !trusted {
            print("⚠️ Accessibility not granted")
            print("📋 Transcribed text: [REDACTED - \(text.count) characters]")
            showError("Accessibility permission required to paste text. Please grant in System Settings.\n\nTranscribed: \(text)")
            return
        }

        // Add a space after the text for proper sentence separation
        let textWithSpace = text + " "

        print("📋 Setting pasteboard: [REDACTED - \(textWithSpace.count) characters]")

        // Inject text using pasteboard and Cmd+V simulation
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(textWithSpace, forType: .string)

        // Verify pasteboard was set correctly
        print("✓ Pasteboard set (change count: \(changeCount) -> \(pasteboard.changeCount))")
        print("✓ Pasteboard ready for paste")

        // Wait for pasteboard to be fully updated
        Thread.sleep(forTimeInterval: 0.1)

        print("⌨️ Simulating Cmd+V (single keystroke event)...")

        // Use a different approach: post only keydown event with both flags
        let source = CGEventSource(stateID: .hidSystemState)

        // Create a keydown event for V with Command flag
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)

            print("  → Posted keyDown for V with Cmd")

            // CRITICAL: Small delay before keyUp
            usleep(50000) // 50ms

            // Now post keyUp WITHOUT the Command flag
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
                print("  → Posted keyUp for V")
            }
        }

        print("✓ Text injected via Cmd+V")
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Midori Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func showAbout() {
        print("ℹ️ Showing About window")
        aboutWindow?.show()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
                print("✓ Launch at login disabled")
            } else {
                try service.register()
                print("✓ Launch at login enabled")
            }
            // Update menu checkmark
            if let menu = statusItem?.menu,
               let item = menu.item(withTitle: "Launch at Login") {
                item.state = service.status == .enabled ? .on : .off
            }
        } catch {
            print("❌ Failed to toggle launch at login: \(error.localizedDescription)")
            showError("Failed to change launch at login setting: \(error.localizedDescription)")
        }
    }

    @objc private func restart() {
        print("🔄 Restarting Midori...")

        guard let executableURL = Bundle.main.executableURL else {
            print("❌ Failed to get executable URL")
            showError("Unable to restart: Could not find executable path")
            return
        }

        let task = Process()
        task.executableURL = executableURL

        do {
            try task.run()
            NSApp.terminate(nil)
        } catch {
            print("❌ Failed to restart: \(error.localizedDescription)")
            showError("Failed to restart: \(error.localizedDescription)")
        }
    }

    @objc private func quit() {
        print("👋 Quitting Midori...")
        NSApp.terminate(nil)
    }
}
