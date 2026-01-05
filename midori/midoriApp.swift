//
//  midoriApp.swift
//  midori
//
//  Created by Deepak Patnaik on 06.11.25.
//

import SwiftUI
import AppKit

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
    var chatWindow: ChatWindow?
    var transcriptionManager: TranscriptionManager?
    var aboutWindow: AboutWindow?
    var onboardingWindow: OnboardingWindow?

    // Bulletproof state management
    private var isRecording = false
    private var recordingStartTimer: DispatchWorkItem?
    private var engineStartTimer: DispatchWorkItem?  // Delays engine start until after pop sounds
    private let stateQueue = DispatchQueue(label: "com.midori.stateQueue")

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✓ Midori launching...")

        // Regular app with Dock icon and Command-Tab presence
        NSApp.setActivationPolicy(.regular)

        // Prompt for Accessibility permission (required for text injection)
        // This shows the system dialog and adds app to System Settings automatically
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("✓ Accessibility permission: \(accessibilityEnabled ? "granted" : "needs approval")")

        // Check for API key - required for Grok integration via OpenRouter
        if !KeychainHelper.shared.hasAPIKey() {
            print("⚠️ No API key found - showing setup dialog")
            if !showAPIKeyDialog(isFirstRun: true) {
                // User cancelled - quit the app
                print("❌ API key required - quitting")
                NSApp.terminate(nil)
                return
            }
        }
        print("✓ API key configured")

        // Create menu bar status item
        setupMenuBar()

        // Initialize managers
        audioRecorder = AudioRecorder()
        waveformWindow = WaveformWindow()
        chatWindow = ChatWindow()
        aboutWindow = AboutWindow()

        // Setup chat window callbacks
        setupChatCallbacks()

        // Setup audio recorder callback
        audioRecorder?.onAudioLevelUpdate = { [weak self] level in
            self?.waveformWindow?.updateAudioLevel(level)
        }

        // Initialize key monitor
        keyMonitor = KeyMonitor()
        keyMonitor?.onRightCommandPressed = { [weak self] isPressed in
            self?.handleRightCommandKey(isPressed: isPressed)
        }

        // Check if model has been downloaded before
        let hasDownloadedModel = UserDefaults.standard.bool(forKey: "hasDownloadedModel")

        print("✓ Checking model download status: hasDownloadedModel = \(hasDownloadedModel)")

        if !hasDownloadedModel {
            // First launch - show onboarding window
            print("✓ First launch detected - showing onboarding window")
            showOnboardingAndInitialize()
        } else {
            // Model already downloaded - initialize silently
            print("✓ Model already downloaded - initializing silently")
            initializeTranscriptionManager()
        }

        print("✓ Midori ready - Press Right Command to start recording")
    }

    private func showOnboardingAndInitialize() {
        onboardingWindow = OnboardingWindow()
        onboardingWindow?.show { [weak self] shouldStartDownload in
            guard let self = self else { return }

            if shouldStartDownload {
                // User didn't click retry - this is the initial download
                self.initializeTranscriptionManager()
            } else {
                // User clicked retry
                self.transcriptionManager?.retryInitialization()
            }
        }
    }

    private func initializeTranscriptionManager() {
        transcriptionManager = TranscriptionManager()

        // Setup transcription result callbacks (routing between text injection and chat)
        setupTranscriptionCallbacks()

        // Setup completion callback
        transcriptionManager?.onInitializationComplete = { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                print("✓ Model download complete")
                // Mark as downloaded
                UserDefaults.standard.set(true, forKey: "hasDownloadedModel")

                // Update onboarding window if showing
                if let window = self.onboardingWindow {
                    window.updateStatus(.success)
                    // Give user a moment to see "Ready!" message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        window.close()
                        self.onboardingWindow = nil
                    }
                }

            case .failure(let error):
                print("❌ Model download failed: \(error.localizedDescription)")
                // Update onboarding window with error
                self.onboardingWindow?.updateStatus(.failed("Download failed. Please check your internet connection."))
            }
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

        // Show Chat menu item
        menu.addItem(NSMenuItem(title: "Show Chat", action: #selector(showChat), keyEquivalent: "m"))

        menu.addItem(NSMenuItem.separator())

        // Add API Key menu item
        menu.addItem(NSMenuItem(title: "Set API Key...", action: #selector(showAPIKeySettings), keyEquivalent: "k"))

        // Add About menu item
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))

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

            // Show waveform window immediately (visual feedback)
            self.waveformWindow?.show()

            // Start audio engine FIRST, then play pops after warm-up
            // This ensures Bluetooth devices (AirPods) are fully ready when pops play
            self.audioRecorder?.startRecording()
            print("✅ Audio engine started (warming up)")

            // Wait for engine + Bluetooth to warm up, then play pops as "ready" signal
            let popWork = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                // Only play pops if still in recording state
                self.stateQueue.async {
                    guard self.isRecording else {
                        print("⚠️ Recording cancelled before pops")
                        return
                    }
                    DispatchQueue.main.async {
                        self.playPopSound()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                            self?.playPopSound()
                        }
                        print("✅ Pop sounds played (ready to capture)")
                    }
                }
            }
            self.engineStartTimer = popWork
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50, execute: popWork)
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

        // Cancel pending engine start (if user released key during pop sounds)
        engineStartTimer?.cancel()
        engineStartTimer = nil

        print("✅ Recording stopped")

        // All UI and audio operations must happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Stop recording
            self.audioRecorder?.stopRecording()

            // Show processing indicator (pulsing dots) while transcribing
            self.waveformWindow?.showPulsingDots()

            // Get audio data and transcribe
            if let audioData = self.audioRecorder?.getAudioData() {
                print("📝 Transcribing \(audioData.count) bytes of audio...")
                self.transcriptionManager?.transcribe(audioData: audioData) { [weak self] result in
                    // The onTranscriptionResult callback handles routing
                    // This completion just logs errors and hides dots on failure
                    if case .failure(let error) = result {
                        print("❌ Transcription failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self?.waveformWindow?.hidePulsingDots()
                        }
                    }
                }
            } else {
                print("⚠️ No audio data captured")
                self.waveformWindow?.hidePulsingDots()
            }
        }
    }

    private func applySentenceCase(_ text: String) -> String {
        // Trim whitespace
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Return empty string if text is empty
        guard !result.isEmpty else { return "" }

        // Capitalize first letter
        result = result.prefix(1).uppercased() + result.dropFirst()

        // Add period at the end if not already present
        let punctuation: Set<Character> = [".", "!", "?"]
        if !punctuation.contains(result.last!) {
            result += "."
        }

        // Add trailing space after the sentence (for continuous dictation)
        result += " "

        return result
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

        // Apply sentence case formatting: capitalize first letter, add period and space
        let formattedText = applySentenceCase(text)

        print("📋 Setting pasteboard: [REDACTED - \(formattedText.count) characters]")

        // Inject text using pasteboard and Cmd+V simulation
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(formattedText, forType: .string)

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

    // MARK: - Chat and Transcription Callbacks

    private func setupChatCallbacks() {
        // When user sends a message via keyboard in chat window
        chatWindow?.onSendMessage = { [weak self] message in
            self?.handleChatMessage(message)
        }
    }

    private func setupTranscriptionCallbacks() {
        // Route transcription results to appropriate handler
        transcriptionManager?.onTranscriptionResult = { [weak self] result in
            guard let self = self else { return }

            // Hide processing indicator now that transcription is complete
            self.waveformWindow?.hidePulsingDots()

            switch result {
            case .textToInject(let text):
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }

                if self.chatWindow?.isVisible ?? false {
                    // Chat window is open - append voice input to existing text
                    let currentText = self.chatWindow?.state.inputText ?? ""
                    if !currentText.isEmpty {
                        self.chatWindow?.state.inputText = currentText + " " + trimmed
                    } else {
                        self.chatWindow?.state.inputText = trimmed
                    }
                } else {
                    // Chat window closed - inject at cursor in other apps
                    self.injectText(text)
                }

            case .directAddress(let message):
                // User said "Midori, ..." - open chat window with draft for review
                self.chatWindow?.show(withDraft: message)
            }
        }
    }

    private func handleChatMessage(_ message: String) {
        // Get all conversation history from superjournal
        let history = DatabaseManager.shared.getAllTurns()
            .map { (user: $0.user, assistant: $0.assistant) }

        // Call Grok for response
        Task {
            do {
                let response = try await HaikuClient.shared.chat(message: message, history: history)

                // Update chat window on main thread
                await MainActor.run {
                    self.chatWindow?.addResponse(response)
                }

                // Save to superjournal
                DatabaseManager.shared.addTurn(userMessage: message, assistantMessage: response)

            } catch {
                print("❌ Chat failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.chatWindow?.addResponse("Sorry, I couldn't respond right now. Please try again.")
                    self.chatWindow?.setLoading(false)
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Midori Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Shows the API key input dialog
    /// - Parameter isFirstRun: If true, shows "Quit" button. If false, shows "Cancel" button.
    /// - Returns: true if key was saved, false if user cancelled
    @discardableResult
    private func showAPIKeyDialog(isFirstRun: Bool) -> Bool {
        let alert = NSAlert()
        alert.messageText = "OpenRouter API Key Required"
        alert.informativeText = "Enter your OpenRouter API key to enable Midori's AI features.\n\nGet your key at: openrouter.ai/keys"
        alert.alertStyle = .informational

        // Create text field for API key input
        let inputField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputField.placeholderString = "sk-or-..."

        // Pre-fill with existing key if updating
        if let existingKey = KeychainHelper.shared.getAPIKey() {
            inputField.stringValue = existingKey
        }

        alert.accessoryView = inputField

        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: isFirstRun ? "Quit" : "Cancel")

        // Make the input field first responder
        alert.window.initialFirstResponder = inputField

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let apiKey = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            if apiKey.isEmpty {
                showError("API key cannot be empty.")
                return showAPIKeyDialog(isFirstRun: isFirstRun)
            }

            // Basic validation - OpenRouter keys start with "sk-or-"
            if !apiKey.hasPrefix("sk-or-") {
                showError("Invalid API key format. OpenRouter keys start with 'sk-or-'.")
                return showAPIKeyDialog(isFirstRun: isFirstRun)
            }

            do {
                try KeychainHelper.shared.saveAPIKey(apiKey)
                print("✓ API key saved successfully")
                return true
            } catch {
                showError("Failed to save API key: \(error.localizedDescription)")
                return false
            }
        }

        return false
    }

    @objc private func showAPIKeySettings() {
        print("🔑 Showing API Key settings")
        showAPIKeyDialog(isFirstRun: false)
    }

    @objc private func showChat() {
        print("💬 Showing Chat window")
        chatWindow?.show(withDraft: "")
    }

    @objc private func showAbout() {
        print("ℹ️ Showing About window")
        aboutWindow?.show()
    }

    @objc private func restart() {
        print("🔄 Restarting Midori...")

        // Clean up current state
        audioRecorder?.stopRecording()
        audioRecorder = nil
        waveformWindow?.hide()

        // Reset state flags
        stateQueue.sync {
            isRecording = false
            recordingStartTimer?.cancel()
            recordingStartTimer = nil
            engineStartTimer?.cancel()
            engineStartTimer = nil
        }

        guard let executableURL = Bundle.main.executableURL else {
            print("❌ Failed to get executable URL")
            showError("Unable to restart: Could not find executable path")
            return
        }

        let task = Process()
        task.executableURL = executableURL

        do {
            try task.run()
            // Small delay to let new process start before terminating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSApp.terminate(nil)
            }
        } catch {
            print("❌ Failed to restart: \(error.localizedDescription)")
            showError("Failed to restart: \(error.localizedDescription)")
        }
    }

    @objc private func quit() {
        print("👋 Quitting Midori...")
        NSApp.terminate(nil)
    }

    private func playPopSound() {
        NSSound(named: "Pop")?.play()
    }
}
