//
//  KeyMonitor.swift
//  midori
//
//  Global key monitoring for Right Command key
//

import AppKit
import Carbon

class KeyMonitor {
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var isRightCommandPressed = false

    var onRightCommandPressed: ((Bool) -> Void)?

    /// Called when Left Command is tapped while Right Command is held (escape hatch trigger)
    var onLeftCommandTapped: (() -> Void)?

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

        print("✓ Key monitor initialized - watching for Right Command key")
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let isCommandPressed = event.modifierFlags.contains(.command)
        let keyCode = event.keyCode

        // Right Command key (keyCode 54) - controls recording
        if keyCode == 54 {
            let newState = isCommandPressed

            // Only trigger callback if state changed
            if newState != isRightCommandPressed {
                isRightCommandPressed = newState
                print("⌘ Right Command key: \(newState ? "DOWN" : "UP")")
                onRightCommandPressed?(newState)
            }
        }

        // Left Command key (keyCode 55) - escape hatch when Right Command is held
        if keyCode == 55 && isCommandPressed && isRightCommandPressed {
            print("⌘ Left Command tapped while recording - escape hatch triggered")
            onLeftCommandTapped?()
        }
    }

    private func stopMonitoring() {
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
        }
        print("✓ Key monitor stopped")
    }
}
