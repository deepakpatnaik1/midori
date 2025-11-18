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
    @ObservedObject private var dictionaryManager = DictionaryManager.shared
    @State private var targetPhrase: String = ""
    @State private var isTraining: Bool = false
    @State private var trainingProgress: String = ""
    @State private var recordingTimer: DispatchWorkItem?
    @State private var statusMessage: String = ""
    @State private var consecutiveExists: Int = 0

    @Environment(\.dismiss) private var dismiss

    private weak var audioRecorder: AudioRecorder?
    private weak var transcriptionManager: TranscriptionManager?

    init(audioRecorder: AudioRecorder?, transcriptionManager: TranscriptionManager?) {
        self.audioRecorder = audioRecorder
        self.transcriptionManager = transcriptionManager
    }

    private var trainingSamples: [(incorrect: String, correct: String)] {
        dictionaryManager.trainingSamples
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

                // Status message
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 10))
                        .foregroundColor(statusMessage.contains("New variant") ? .green : .orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
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

                    if isTraining {
                        Button(action: cancelTraining) {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 28)
                                .background(Color.red)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
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

            Divider()

            // Bottom action buttons
            HStack(spacing: 12) {
                Button(action: handleCancel) {
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 80, height: 28)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: handleOK) {
                    Text("OK")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 28)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 600, height: 500)
        .preferredColorScheme(.dark)
    }

    private func loadTrainingSamples() {
        // Samples are automatically loaded from DictionaryManager.shared
    }

    private func startTraining() {
        guard !targetPhrase.isEmpty, let recorder = audioRecorder, let transcription = transcriptionManager else {
            return
        }

        isTraining = true
        trainingProgress = "Recording..."

        // Start recording
        recorder.startRecording()

        // Create timer for 3 seconds
        let timer = DispatchWorkItem { [self] in
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
                    recordingTimer = nil

                    switch result {
                    case .success(let text):
                        // Add training sample
                        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanedText.isEmpty {
                            // Normalize: lowercase and remove punctuation
                            let normalizedText = cleanedText.lowercased()
                                .components(separatedBy: CharacterSet.punctuationCharacters)
                                .joined()
                                .trimmingCharacters(in: .whitespaces)

                            // Check if this variant already exists (entries are already normalized)
                            let exists = trainingSamples.contains {
                                return $0.incorrect == normalizedText
                            }

                            if exists {
                                consecutiveExists += 1
                                statusMessage = "Exists"
                                print("⚠️ Training sample already exists: '\(cleanedText)'")

                                // Auto-conclude after 3 consecutive "Exists"
                                if consecutiveExists >= 3 {
                                    print("✓ Training auto-concluded: 3 consecutive duplicates detected")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        // Reset for next word/phrase instead of closing
                                        targetPhrase = ""
                                        statusMessage = "Training concluded - ready for next phrase"
                                        consecutiveExists = 0
                                        // TODO: Save current samples to persistent storage
                                    }
                                }
                            } else {
                                consecutiveExists = 0
                                statusMessage = "New variant added"
                                dictionaryManager.addSample(incorrect: cleanedText, correct: targetPhrase)
                                print("✓ Training sample added: '\(cleanedText)' -> '\(targetPhrase)'")
                            }
                        }

                    case .failure(let error):
                        statusMessage = "Transcription failed"
                        print("❌ Training transcription failed: \(error.localizedDescription)")
                    }
                }
            }
        }

        recordingTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timer)
    }

    private func cancelTraining() {
        // Cancel the timer
        recordingTimer?.cancel()
        recordingTimer = nil

        // Stop recording
        audioRecorder?.stopRecording()

        // Reset state
        isTraining = false
        trainingProgress = ""

        print("⚠️ Training cancelled by user")
    }

    private func handleCancel() {
        // Discard all training samples and close window
        dictionaryManager.clearAll()
        NSApp.keyWindow?.close()
    }

    private func handleOK() {
        // Training samples are already saved automatically
        print("✓ Training concluded with \(trainingSamples.count) samples")
        NSApp.keyWindow?.close()
    }

    private func deleteSample(at index: Int) {
        dictionaryManager.removeSample(at: index)
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
