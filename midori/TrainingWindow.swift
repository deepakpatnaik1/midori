//
//  TrainingWindow.swift
//  midori
//
//  Custom dictionary training UI
//

import SwiftUI
import AppKit

class TrainingWindow {
    private var window: NSWindow?
    private weak var audioRecorder: AudioRecorder?
    private weak var transcriptionManager: TranscriptionManager?

    init(audioRecorder: AudioRecorder?, transcriptionManager: TranscriptionManager?) {
        self.audioRecorder = audioRecorder
        self.transcriptionManager = transcriptionManager
    }

    func show() {
        // If window already exists, just bring it to front
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
        let contentView = TrainingView(
            audioRecorder: audioRecorder,
            transcriptionManager: transcriptionManager
        )
        let hostingController = NSHostingController(rootView: contentView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Custom Dictionary"
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

struct TrainingView: View {
    @State private var trainingSamples: [(incorrect: String, correct: String)] = []
    @State private var targetPhrase: String = ""
    @State private var isTraining: Bool = false
    @State private var trainingProgress: String = ""

    private weak var audioRecorder: AudioRecorder?
    private weak var transcriptionManager: TranscriptionManager?

    init(audioRecorder: AudioRecorder?, transcriptionManager: TranscriptionManager?) {
        self.audioRecorder = audioRecorder
        self.transcriptionManager = transcriptionManager
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Custom Dictionary")
                    .font(.system(size: 13, weight: .semibold))

                Text("Train words and phrases by recording variations")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Training input section
            VStack(spacing: 12) {
                TextField("Enter word or phrase", text: $targetPhrase)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                    .disabled(isTraining)

                Button(action: startTraining) {
                    HStack(spacing: 6) {
                        if isTraining {
                            ProgressView()
                                .scaleEffect(0.6)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isTraining ? trainingProgress : "Start Training")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 140, height: 28)
                    .background(buttonColor())
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(targetPhrase.isEmpty || isTraining)
            }
            .padding(16)

            Divider()

            // Training samples list
            if trainingSamples.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))

                    VStack(spacing: 4) {
                        Text("No training samples yet")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Enter a word or phrase above and click Start Training")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(trainingSamples.enumerated()), id: \.offset) { index, sample in
                            HStack(spacing: 12) {
                                // Transcribed text (left side)
                                Text(sample.incorrect)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary.opacity(0.5))

                                // Corrected text (right side)
                                Text(sample.correct)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)

                                // Delete button
                                Button(action: {
                                    deleteSample(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(index % 2 == 0 ? Color(NSColor.controlBackgroundColor).opacity(0.3) : Color.clear)
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadTrainingSamples)
    }

    private func loadTrainingSamples() {
        // TODO: Load from persistent storage when implemented
        trainingSamples = []
    }

    private func startTraining() {
        guard !targetPhrase.isEmpty, let recorder = audioRecorder, let transcription = transcriptionManager else {
            return
        }

        isTraining = true
        trainingProgress = "Recording..."

        // Start recording
        recorder.startRecording()

        // Record for 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            trainingProgress = "Processing..."
            recorder.stopRecording()

            // Get audio data and transcribe
            guard let audioData = recorder.getAudioData() else {
                print("⚠️ No audio data captured in training")
                isTraining = false
                return
            }

            transcription.transcribe(audioData: audioData) { [self] result in
                DispatchQueue.main.async {
                    isTraining = false
                    trainingProgress = ""

                    switch result {
                    case .success(let text):
                        // Add training sample
                        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanedText.isEmpty {
                            trainingSamples.append((incorrect: cleanedText, correct: targetPhrase))
                            // TODO: Save to persistent storage
                            print("✓ Training sample added: '\(cleanedText)' -> '\(targetPhrase)'")
                        }

                    case .failure(let error):
                        print("❌ Training transcription failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func deleteSample(at index: Int) {
        // TODO: Remove from persistent storage when implemented
        trainingSamples.remove(at: index)
    }

    private func buttonColor() -> Color {
        if targetPhrase.isEmpty {
            return Color.blue.opacity(0.5)
        }

        if isTraining {
            if trainingProgress == "Recording..." {
                return Color.red
            } else if trainingProgress == "Processing..." {
                return Color.orange
            }
        }

        return Color.blue
    }
}
