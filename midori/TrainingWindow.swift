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

    init() {
    }

    func show() {
        // If window already exists, just bring it to front
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
        let contentView = TrainingView()
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
    @State private var corrections: [(key: String, value: String)] = []
    @State private var newIncorrect: String = ""
    @State private var newCorrect: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Dictionary")
                    .font(.system(size: 16, weight: .semibold))

                Text("Add corrections for words the transcription gets wrong")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Add new correction section
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transcribes as:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        TextField("clawed", text: $newIncorrect)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Should be:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        TextField("Claude", text: $newCorrect)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }

                    Button(action: addCorrection) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .disabled(newIncorrect.isEmpty || newCorrect.isEmpty)
                    .padding(.top, 14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Corrections list
            if corrections.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No corrections yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text("Add your first correction above")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(corrections, id: \.key) { correction in
                            HStack(spacing: 12) {
                                // Incorrect word
                                Text(correction.key)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 150, alignment: .leading)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary.opacity(0.5))

                                // Correct word
                                Text(correction.value)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Delete button
                                Button(action: {
                                    deleteCorrection(correction.key)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 600, height: 500)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadCorrections)
    }

    private func loadCorrections() {
        // TODO: Load from CorrectionLayer when implemented
        corrections = []
    }

    private func addCorrection() {
        guard !newIncorrect.isEmpty, !newCorrect.isEmpty else { return }

        // TODO: Save to CorrectionLayer when implemented
        corrections.append((key: newIncorrect, value: newCorrect))
        corrections.sort { $0.key < $1.key }

        // Clear inputs
        newIncorrect = ""
        newCorrect = ""
    }

    private func deleteCorrection(_ incorrect: String) {
        // TODO: Remove from CorrectionLayer when implemented
        corrections.removeAll { $0.key == incorrect }
    }
}
