//
//  midoriApp.swift
//  midori
//
//  Created by Deepak Patnaik on 06.11.25.
//

import SwiftUI
import AppKit
import ServiceManagement

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
        waveformWindow = WaveformWindow()

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
        menu.addItem(NSMenuItem(title: "Restart", action: #selector(restart), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func handleRightCommandKey(isPressed: Bool) {
        if isPressed {
            print("🎤 Right Command pressed - Starting recording...")
            startRecording()
        } else {
            print("🔴 Right Command released - Stopping recording...")
            stopRecording()
        }
    }

    private func startRecording() {
        // Wait 1 second before showing waveform and playing pop sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // Play pop sound - MULTIPLE TIMES for EXTRA LOUD effect
            if let sound = NSSound(named: "Pop") {
                sound.volume = 1.0  // Maximum volume!
                sound.play()
                // Play it again immediately for double volume effect
                if let sound2 = NSSound(named: "Pop") {
                    sound2.volume = 1.0
                    sound2.play()
                }
                print("🔊🔊 Pop sound played (EXTRA LOUD - 2x)")
            } else {
                NSSound.beep()
                print("🔊 Beep sound played (Pop not available)")
            }

            // Show waveform window
            self?.waveformWindow?.show()

            // Start audio recording
            self?.audioRecorder?.startRecording()
        }
    }

    private func stopRecording() {
        // Stop recording
        audioRecorder?.stopRecording()

        // Hide waveform
        waveformWindow?.hide()

        // Get audio data and transcribe
        if let audioData = audioRecorder?.getAudioData() {
            print("📝 Transcribing audio...")
            transcriptionManager?.transcribe(audioData: audioData) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        print("✓ Transcription complete: \(text)")
                        self?.injectText(text)
                    case .failure(let error):
                        print("❌ Transcription failed: \(error.localizedDescription)")
                        // Silent failure - no dialog box, just log it
                    }
                }
            }
        }
    }

    private func injectText(_ text: String) {
        // Check accessibility permissions
        let trusted = AXIsProcessTrusted()

        if !trusted {
            print("⚠️ Accessibility not granted")
            print("📋 Transcribed text: \(text)")
            showError("Accessibility permission required to paste text. Please grant in System Settings.\n\nTranscribed: \(text)")
            return
        }

        // Add a space after the text for proper sentence separation
        let textWithSpace = text + " "

        print("📋 Setting pasteboard: \"\(textWithSpace)\" (\(textWithSpace.count) chars)")

        // Inject text using pasteboard and Cmd+V simulation
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(textWithSpace, forType: .string)

        // Verify pasteboard was set correctly
        let pasteboardText = pasteboard.string(forType: .string)
        print("✓ Pasteboard set (change count: \(changeCount) -> \(pasteboard.changeCount))")
        print("✓ Pasteboard contains: \"\(pasteboardText ?? "nil")\"")

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

    @objc private func restart() {
        print("🔄 Restarting Midori...")
        let task = Process()
        task.launchPath = Bundle.main.executablePath
        task.launch()
        NSApp.terminate(nil)
    }

    @objc private func quit() {
        print("👋 Quitting Midori...")
        NSApp.terminate(nil)
    }
}
