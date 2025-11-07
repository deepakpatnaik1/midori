//
//  WaveformView.swift
//  midori
//
//  Dancing 9-bar waveform visualization with purple-to-cyan gradient
//  Bars start as small circles and grow into dancing bars based on audio level
//

import SwiftUI

struct WaveformView: View {
    @Binding var audioLevel: Float

    // Individual bar heights - start as tiny circles
    @State private var barHeights: [CGFloat] = Array(repeating: 0.23, count: 9)

    // Individual animation timers for each bar
    @State private var barPhases: [Double] = Array(repeating: 0.0, count: 9)
    @State private var timer: Timer?

    // Each bar has its own personality - fixed max height for consistency
    @State private var barMaxHeights: [CGFloat] = []

    // Vivid colors for each circle/bar (left to right gradient) - highly saturated!
    let barColors: [Color] = [
        Color(red: 1.0, green: 0.0, blue: 1.0),     // Hot Magenta (leftmost)
        Color(red: 1.0, green: 0.1, blue: 0.95),    // Bright Pink
        Color(red: 0.9, green: 0.2, blue: 1.0),     // Vivid Purple-Pink
        Color(red: 0.7, green: 0.2, blue: 1.0),     // Electric Purple
        Color(red: 0.5, green: 0.4, blue: 1.0),     // Purple-Blue (center)
        Color(red: 0.3, green: 0.6, blue: 1.0),     // Bright Blue
        Color(red: 0.2, green: 0.8, blue: 1.0),     // Sky Blue
        Color(red: 0.0, green: 0.9, blue: 1.0),     // Electric Cyan
        Color(red: 0.0, green: 1.0, blue: 1.0)      // Pure Cyan (rightmost)
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<9, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColors[index])
                    .frame(width: 8, height: barHeights[index] * 35)
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

        // Give each bar its own fixed maximum height "personality"
        // Some bars are tall, some medium, some short - but consistent
        barMaxHeights = (0..<9).map { _ in CGFloat.random(in: 1.0...2.5) }

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

        // ULTRA sensitive amplification for very soft speaking
        // Using exponential curve to boost low levels dramatically
        let boostedIntensity = pow(intensity * 12.0, 0.65)  // Even more boost!
        let amplifiedIntensity = min(boostedIntensity, 1.0)

        // Ultra-low threshold for detecting very soft speech
        let isSpeaking = intensity > 0.03

        for i in 0..<9 {
            if !isSpeaking {
                // Keep as tiny circles when silent with slight variation
                barHeights[i] = 0.22 + CGFloat.random(in: 0...0.02)
            } else {
                // Each bar dances with its own unique frequency
                let frequency = 4.0 + Double(i) * 0.7
                let phase = barPhases[i]

                // Primary wave motion
                let wave1 = sin(currentTime * frequency + phase)

                // Secondary wave with different frequency
                let wave2 = sin(currentTime * (frequency * 1.7) + phase * 2.1) * 0.5

                // Tertiary wave for even more variety
                let wave3 = sin(currentTime * (frequency * 2.3) + phase * 1.6) * 0.4

                // Combine all waves
                let combinedWave = wave1 + wave2 + wave3

                // Normalize to 0-1 range
                let normalized = (combinedWave + 1.9) / 3.8

                // Use this bar's fixed maximum height personality
                let thisBarMaxHeight = barMaxHeights.isEmpty ? 2.0 : barMaxHeights[i]
                let minHeight: CGFloat = 0.25

                // Calculate height - bar dances between min and its personal max
                let targetHeight = minHeight + (CGFloat(normalized) * (thisBarMaxHeight - minHeight))

                // Apply super-sensitive amplified intensity
                barHeights[i] = targetHeight * amplifiedIntensity
            }
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
