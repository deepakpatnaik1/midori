//
//  AboutWindow.swift
//  midori
//
//  Standard macOS about dialog
//

import SwiftUI
import AppKit

class AboutWindow {
    private var window: NSWindow?

    func show() {
        // If window already exists, just bring it to front
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
        let contentView = AboutView()
        let hostingController = NSHostingController(rootView: contentView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "About Midori"
        newWindow.contentViewController = hostingController
        newWindow.center()
        newWindow.isReleasedWhenClosed = false

        // Store reference
        window = newWindow

        // Show window
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App icon or waveform visualization
            Image(systemName: "waveform")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // App name
            Text("Midori")
                .font(.system(size: 32, weight: .bold))

            // Version
            Text("Version \(appVersion)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // Copyright
            Text("© 2025 Deepak Patnaik")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}
