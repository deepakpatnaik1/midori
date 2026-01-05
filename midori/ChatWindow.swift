//
//  ChatWindow.swift
//  midori
//
//  Floating chat window for conversations with Midori
//

import SwiftUI
import AppKit
import Combine

/// Message in the chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

/// Observable state for the chat window
class ChatWindowState: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""

    func addUserMessage(_ text: String) {
        messages.append(ChatMessage(content: text, isUser: true, timestamp: Date()))
    }

    func addMidoriMessage(_ text: String) {
        messages.append(ChatMessage(content: text, isUser: false, timestamp: Date()))
    }

    func clear() {
        messages.removeAll()
        inputText = ""
        isLoading = false
    }

    /// Load conversation history from superjournal
    func loadHistory() {
        messages.removeAll()
        let turns = DatabaseManager.shared.getAllTurns()
        for turn in turns {
            messages.append(ChatMessage(content: turn.user, isUser: true, timestamp: turn.date))
            messages.append(ChatMessage(content: turn.assistant, isUser: false, timestamp: turn.date))
        }
    }
}

class ChatWindow {
    private var window: NSWindow?
    private var hostingController: NSHostingController<ChatWindowContent>?
    private(set) var state = ChatWindowState()

    /// Callback when user sends a message (voice or keyboard)
    var onSendMessage: ((String) -> Void)?

    init() {
        setupWindow()
    }

    private func setupWindow() {
        let contentView = ChatWindowContent(state: state, onSend: { [weak self] text in
            self?.onSendMessage?(text)
        }, onClose: { [weak self] in
            self?.hide()
        })

        hostingController = NSHostingController(rootView: contentView)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window?.contentViewController = hostingController
        window?.backgroundColor = NSColor.windowBackgroundColor
        window?.isOpaque = true
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window?.hasShadow = true
        window?.title = "Midori"
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.isMovableByWindowBackground = true

        // Set size constraints
        window?.minSize = NSSize(width: 250, height: 300)
        window?.maxSize = NSSize(width: 600, height: 800)

        // Position at bottom center of screen (above waveform position)
        positionAtBottomCenter()

        // Handle escape key to close
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.hide()
                return nil
            }
            return event
        }

        print("✓ Chat window initialized")
    }

    private func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        guard let window = window else { return }

        let screenFrame = screen.frame
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 120 // Above the waveform position

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Show the chat window with text in the input field for review
    func show(withDraft draft: String) {
        // Load conversation history
        state.loadHistory()
        // Put the draft in the input field for review (not sent yet)
        state.inputText = draft
        state.isLoading = false
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        print("✓ Chat window shown with draft: \"\(draft)\"")
    }

    /// Add Midori's response to the chat
    func addResponse(_ text: String) {
        state.isLoading = false
        state.addMidoriMessage(text)
        print("✓ Added Midori response: \"\(text)\"")
    }

    /// Show loading state
    func setLoading(_ loading: Bool) {
        state.isLoading = loading
    }

    /// Hide the chat window
    func hide() {
        window?.orderOut(nil)
        print("✓ Chat window hidden")
    }

    /// Check if window is visible
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
}
