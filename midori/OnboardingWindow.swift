//
//  OnboardingWindow.swift
//  midori
//
//  Model download onboarding window - shown on first launch
//

import SwiftUI
import AppKit
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var downloadStatus: DownloadStatus = .downloading

    enum DownloadStatus {
        case downloading
        case success
        case failed(String)
    }
}

class OnboardingWindow: NSObject {
    private var window: NSWindow?
    private var hostingController: NSHostingController<OnboardingView>?
    private var viewModel = OnboardingViewModel()

    func show(onComplete: @escaping (Bool) -> Void) {
        let contentView = OnboardingView(viewModel: viewModel, onComplete: onComplete)
        hostingController = NSHostingController(rootView: contentView)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window?.center()
        window?.title = "Welcome to Midori"
        window?.contentViewController = hostingController
        window?.isReleasedWhenClosed = false
        window?.level = .floating

        // Activate app and show window
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)

        // Prevent closing during download
        window?.standardWindowButton(.closeButton)?.isEnabled = false

        print("✓ Onboarding window shown")
    }

    func updateStatus(_ status: OnboardingViewModel.DownloadStatus) {
        viewModel.downloadStatus = status
    }

    func close() {
        window?.close()
        window = nil
        hostingController = nil
    }
}

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: (Bool) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon/branding area
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.2, blue: 1.0),  // Vibrant magenta
                            Color(red: 0.0, green: 0.8, blue: 1.0)    // Vibrant cyan
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Title
            Text("Welcome to Midori")
                .font(.system(size: 24, weight: .semibold))

            // Tagline
            Text("Type at the speed of Talk")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
                .padding(.top, -16)

            // Privacy message
            VStack(spacing: 8) {
                Text("Complete data privacy")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Midori uses on-device AI for speech recognition")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)

                Text("Your voice never leaves your computer")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            // Status area
            VStack(spacing: 12) {
                switch viewModel.downloadStatus {
                case .downloading:
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(height: 20)

                    Text("Downloading model...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)

                    Text("Ready!")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                case .failed(let error):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)

                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    HStack(spacing: 12) {
                        Button("Retry") {
                            viewModel.downloadStatus = .downloading
                            onComplete(false) // Trigger retry
                        }
                        .controlSize(.large)

                        Button("Quit") {
                            NSApplication.shared.terminate(nil)
                        }
                        .controlSize(.large)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(height: 60)

            Spacer()
        }
        .frame(width: 480, height: 340)
        .onAppear {
            // Start download immediately
            onComplete(true)
        }
    }
}
