//
//  WaveformView.swift
//  midori
//
//  9-bar waveform visualization with purple-to-cyan gradient
//  Matches the voice.png logo design
//

import SwiftUI

struct WaveformView: View {
    @Binding var audioLevel: Float
    @State private var barHeights: [CGFloat] = [0.3, 0.5, 0.7, 0.9, 1.0, 0.9, 0.7, 0.5, 0.3]

    // Purple to cyan gradient colors
    let gradientColors = [
        Color(red: 0.58, green: 0.29, blue: 0.82), // Purple/magenta top
        Color(red: 0.29, green: 0.71, blue: 0.91)  // Blue/cyan bottom
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<9, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: barHeights[index] * 40 * CGFloat(audioLevel))
                    .animation(.easeInOut(duration: 0.1), value: audioLevel)
            }
        }
        .frame(height: 50)
        .onChange(of: audioLevel) { oldValue, newValue in
            updateBarHeights(level: newValue)
        }
    }

    private func updateBarHeights(level: Float) {
        // Symmetric pattern for 9 bars (matches logo)
        let basePattern: [CGFloat] = [0.3, 0.5, 0.7, 0.9, 1.0, 0.9, 0.7, 0.5, 0.3]

        // Add some variation based on audio level
        barHeights = basePattern.map { baseHeight in
            let variation = CGFloat.random(in: 0.8...1.2)
            return baseHeight * variation * CGFloat(max(level, 0.2))
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
                                Color(red: 0.58, green: 0.29, blue: 0.82),
                                Color(red: 0.29, green: 0.71, blue: 0.91)
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
