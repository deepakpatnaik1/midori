//
//  WaveformWindow.swift
//  midori
//
//  Floating window for waveform visualization at bottom center of screen
//

import SwiftUI
import AppKit
import Combine

class WaveformWindowState: ObservableObject {
    @Published var audioLevel: Float = 0.5
    @Published var showingWaveform = false
    @Published var showingDots = false
}

class WaveformWindow {
    private var window: NSWindow?
    private var hostingController: NSHostingController<WaveformWindowContent>?
    private var state = WaveformWindowState()

    init() {
        setupWindow()
    }

    private func setupWindow() {
        let contentView = WaveformWindowContent(state: state)

        hostingController = NSHostingController(rootView: contentView)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window?.contentViewController = hostingController
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window?.ignoresMouseEvents = true
        window?.hasShadow = false

        // Position at bottom center of screen
        positionAtBottomCenter()

        print("✓ Waveform window initialized")
    }

    private func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        guard let window = window else { return }

        let screenFrame = screen.frame
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.minY + 100 // 100 points from bottom

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func show() {
        state.showingWaveform = true
        state.showingDots = false
        window?.orderFrontRegardless()
        print("✓ Waveform shown")
    }

    func hide() {
        state.showingWaveform = false
        window?.orderOut(nil)
        print("✓ Waveform hidden")
    }

    func showPulsingDots() {
        state.showingWaveform = false
        state.showingDots = true
        window?.orderFrontRegardless()
        print("✓ Pulsing dots shown")
    }

    func hidePulsingDots() {
        state.showingDots = false
        window?.orderOut(nil)
        print("✓ Pulsing dots hidden")
    }

    func updateAudioLevel(_ level: Float) {
        state.audioLevel = level
    }
}

struct WaveformWindowContent: View {
    @ObservedObject var state: WaveformWindowState

    var body: some View {
        ZStack {
            if state.showingWaveform {
                WaveformView(audioLevel: $state.audioLevel)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 10)
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            if state.showingDots {
                PulsingDotsView()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 10)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 120, height: 80)
        .animation(.easeInOut(duration: 0.3), value: state.showingWaveform)
        .animation(.easeInOut(duration: 0.3), value: state.showingDots)
    }
}
