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
                // Base state: straight line of dots (all same height)
                barHeights[i] = 0.23
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
    @State private var activeIndex = 0

    // Same gradient colors as waveform
    let dotColors: [Color] = [
        Color(red: 1.0, green: 0.0, blue: 1.0),     // Magenta
        Color(red: 0.5, green: 0.4, blue: 1.0),     // Purple
        Color(red: 0.0, green: 1.0, blue: 1.0)      // Cyan
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(dotColors[index])
                    .frame(width: 10, height: 10)
                    .scaleEffect(activeIndex == index ? 1.4 : 0.8)
                    .opacity(activeIndex == index ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
            }
        }
        .onAppear {
            startThinkingAnimation()
        }
    }

    private func startThinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            activeIndex = (activeIndex + 1) % 3
        }
    }
}
