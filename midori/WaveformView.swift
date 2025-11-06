//
//  WaveformView.swift
//  midori
//
//  Dancing 9-bar waveform visualization with purple-to-cyan gradient
//  Bars start at uniform height and dance independently based on audio level
//

import SwiftUI

struct WaveformView: View {
    @Binding var audioLevel: Float

    // Individual bar heights - all start uniform
    @State private var barHeights: [CGFloat] = Array(repeating: 1.0, count: 9)

    // Individual animation timers for each bar
    @State private var barPhases: [Double] = Array(repeating: 0.0, count: 9)
    @State private var timer: Timer?

    // Purple to cyan gradient colors (matching voice.png)
    let gradientColors = [
        Color(red: 1.0, green: 0.0, blue: 1.0),   // Magenta top
        Color(red: 0.58, green: 0.29, blue: 0.82), // Purple middle
        Color(red: 0.29, green: 0.71, blue: 0.91), // Blue
        Color(red: 0.0, green: 1.0, blue: 1.0)     // Cyan bottom
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<9, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: barHeights[index] * 50)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: barHeights[index])
            }
        }
        .frame(height: 60)
        .onAppear {
            startDancing()
        }
        .onDisappear {
            stopDancing()
        }
        .onChange(of: audioLevel) { oldValue, newValue in
            // Audio level changes drive the dancing intensity
            updateDancingIntensity(level: newValue)
        }
    }

    private func startDancing() {
        // Initialize random phases for each bar
        barPhases = (0..<9).map { _ in Double.random(in: 0...2 * .pi) }

        // Start animation timer at 60fps
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            updateBarHeights()
        }
    }

    private func stopDancing() {
        timer?.invalidate()
        timer = nil
    }

    private func updateDancingIntensity(level: Float) {
        // Audio level affects how much the bars dance
        // Higher level = more energetic movement
        // Low/zero level = calm, minimal movement
    }

    private func updateBarHeights() {
        let currentTime = Date().timeIntervalSince1970

        // Audio level determines dancing intensity
        let intensity = CGFloat(audioLevel)

        // When silent (low audio), bars become more stable
        let stabilityFactor: CGFloat = intensity < 0.1 ? 0.05 : intensity

        for i in 0..<9 {
            // Each bar has its own frequency and phase for independent movement
            let frequency = 2.0 + Double(i) * 0.3  // Different frequency per bar
            let phase = barPhases[i]

            // Create dancing motion using sine waves with individual characteristics
            let baseMotion = sin(currentTime * frequency + phase)

            // Add secondary motion for more complex animation
            let secondaryFrequency = 3.0 + Double(i) * 0.2
            let secondaryMotion = sin(currentTime * secondaryFrequency + phase * 1.5) * 0.3

            // Combine motions and apply intensity
            let combinedMotion = (baseMotion + secondaryMotion) * Double(stabilityFactor)

            // Calculate final height (0.4 to 1.0 range for nice visual)
            // When silent: bars hover around 0.7 with minimal movement
            // When speaking: bars dance between 0.4 and 1.0
            let minHeight: CGFloat = intensity < 0.1 ? 0.65 : 0.4
            let maxHeight: CGFloat = intensity < 0.1 ? 0.75 : 1.0
            let normalizedHeight = (CGFloat(combinedMotion) + 1.0) / 2.0  // 0 to 1

            barHeights[i] = minHeight + (normalizedHeight * (maxHeight - minHeight))
        }
    }
}

struct PulsingDotsView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.0, blue: 1.0),
                                Color(red: 0.58, green: 0.29, blue: 0.82),
                                Color(red: 0.29, green: 0.71, blue: 0.91),
                                Color(red: 0.0, green: 1.0, blue: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 10)
            }
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.3
            }
        }
    }
}
