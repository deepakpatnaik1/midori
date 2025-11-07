//
//  TranscriptionManager.swift
//  midori
//
//  Transcription manager using FluidAudio + Parakeet V2 CoreML
//

import Foundation
import FluidAudio
import AVFoundation

enum TranscriptionError: Error {
    case noAudioData
    case transcriptionFailed
    case modelNotFound
    case modelInitializationFailed
    case audioConversionFailed

    var localizedDescription: String {
        switch self {
        case .noAudioData:
            return "No audio data to transcribe"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .modelNotFound:
            return "Parakeet model not found. Please download the model."
        case .modelInitializationFailed:
            return "Failed to initialize Parakeet model"
        case .audioConversionFailed:
            return "Failed to convert audio to required format"
        }
    }
}

class TranscriptionManager {
    private var asrManager: AsrManager?
    private var isInitialized = false

    init() {
        print("✓ TranscriptionManager initialized")
        print("🔄 Loading Parakeet V2 CoreML model...")

        // Initialize FluidAudio asynchronously
        Task {
            await initializeModel()
        }
    }

    private func initializeModel() async {
        do {
            // Download and load Parakeet V2 model (English-optimized)
            print("📥 Downloading Parakeet V2 model if needed...")
            let models = try await AsrModels.downloadAndLoad(version: .v2)

            // Create ASR manager with default config
            asrManager = AsrManager(config: .default)
            try await asrManager?.initialize(models: models)

            isInitialized = true
            print("✓ Parakeet V2 model loaded and ready")
        } catch {
            print("❌ Failed to initialize Parakeet model: \(error.localizedDescription)")
            isInitialized = false
        }
    }

    func transcribe(audioData: Data, completion: @escaping (Result<String, TranscriptionError>) -> Void) {
        // Transcribe using FluidAudio/Parakeet
        Task {
            await transcribeAsync(audioData: audioData, completion: completion)
        }
    }

    private func transcribeAsync(audioData: Data, completion: @escaping (Result<String, TranscriptionError>) -> Void) async {
        print("📝 Starting Parakeet transcription...")

        // Wait for model to be initialized if it isn't yet
        if !isInitialized {
            print("⏳ Waiting for model to initialize...")
            // Give it a moment to initialize
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            if !isInitialized {
                print("❌ Model not initialized")
                DispatchQueue.main.async {
                    completion(.failure(.modelInitializationFailed))
                }
                return
            }
        }

        guard let manager = asrManager else {
            print("❌ ASR manager not available")
            DispatchQueue.main.async {
                completion(.failure(.modelNotFound))
            }
            return
        }

        do {
            // Convert audio data to 16kHz mono samples (required by FluidAudio)
            let samples = try convertAudioTo16kHzMono(audioData: audioData)

            // Transcribe using FluidAudio
            let result = try await manager.transcribe(samples)

            print("✓ Parakeet transcription complete: [REDACTED - \(result.text.count) characters]")

            DispatchQueue.main.async {
                completion(.success(result.text))
            }
        } catch {
            print("❌ Transcription failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(.transcriptionFailed))
            }
        }
    }

    // Convert audio data to 16kHz mono format required by FluidAudio
    private func convertAudioTo16kHzMono(audioData: Data) throws -> [Float] {
        print("🔄 Converting audio to 16kHz mono...")

        // Extract Float32 samples from raw audio data
        // AVAudioEngine typically captures at 48kHz Float32 mono
        let floatSamples = audioData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
            let buffer = ptr.bindMemory(to: Float.self)
            return Array(buffer)
        }

        print("✓ Extracted \(floatSamples.count) Float32 samples")

        // Downsample from 48kHz to 16kHz (3:1 ratio)
        // AVAudioEngine typically uses 48kHz on macOS
        let downsampleRatio = 3 // 48000 / 16000 = 3
        var resampled: [Float] = []
        resampled.reserveCapacity(floatSamples.count / downsampleRatio)

        for i in stride(from: 0, to: floatSamples.count, by: downsampleRatio) {
            resampled.append(floatSamples[i])
        }

        print("✓ Downsampled to 16kHz: \(resampled.count) samples")
        return resampled
    }
}
