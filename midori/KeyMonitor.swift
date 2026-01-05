//
//  KeyMonitor.swift
//  midori
//
//  Global key monitoring for Right Command key and Escape
//

import AppKit
import Carbon

class KeyMonitor {
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var isRightCommandPressed = false

    var onRightCommandPressed: ((Bool) -> Void)?
    var onEscapePressed: (() -> Void)?

    init() {
        setupMonitors()
    }

    deinit {
        stopMonitoring()
    }

    private func setupMonitors() {
        // Global monitor for modifier keys (Right Command)
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        // Local monitor for modifier keys
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }

        // Global monitor for Escape key
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
        }

        // Local monitor for Escape key
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }

        print("✓ Key monitor initialized - watching for Right Command and Escape keys")
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // Right Command key has keyCode 54
        let isCommandPressed = event.modifierFlags.contains(.command)
        let keyCode = event.keyCode

        // Check if it's specifically the Right Command key
        if keyCode == 54 {
            let newState = isCommandPressed

            // Only trigger callback if state changed
            if newState != isRightCommandPressed {
                isRightCommandPressed = newState
                print("⌘ Right Command key: \(newState ? "DOWN" : "UP")")
                onRightCommandPressed?(newState)
            }
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        // Escape key has keyCode 53
        if event.keyCode == 53 {
            print("⎋ Escape key pressed")
            onEscapePressed?()
        }
    }

    private func stopMonitoring() {
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        print("✓ Key monitor stopped")
    }
}
