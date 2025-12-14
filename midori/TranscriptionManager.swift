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
    var onInitializationComplete: ((Result<Void, Error>) -> Void)?

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

            // Notify completion on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onInitializationComplete?(.success(()))
            }
        } catch {
            print("❌ Failed to initialize Parakeet model: \(error.localizedDescription)")
            isInitialized = false

            // Notify failure on main thread
            DispatchQueue.main.async { [weak self] in
                self?.onInitializationComplete?(.failure(error))
            }
        }
    }

    func retryInitialization() {
        Task {
            await initializeModel()
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
            print("🔍 Sending \(samples.count) samples to Parakeet (\(Double(samples.count) / 16000.0) seconds of audio)")
            let result = try await manager.transcribe(samples)

            print("✓ Parakeet transcription complete: \(result.text.count) chars")
            print("🔍 Raw Parakeet output: \"\(result.text)\"")

            // Apply custom dictionary corrections
            let correctedText = CorrectionLayer.shared.applyCorrections(to: result.text)
            print("✓ Applied custom dictionary corrections")

            DispatchQueue.main.async {
                completion(.success(correctedText))
            }
        } catch {
            print("❌ Transcription failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(.failure(.transcriptionFailed))
            }
        }
    }

    // Convert audio data to 16kHz mono format required by FluidAudio
    // Built-in Mac microphone captures at 48kHz, so we downsample 3:1
    private func convertAudioTo16kHzMono(audioData: Data) throws -> [Float] {
        // Extract Float32 samples from raw audio data
        let floatSamples = audioData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
            let buffer = ptr.bindMemory(to: Float.self)
            return Array(buffer)
        }

        print("✓ Extracted \(floatSamples.count) Float32 samples at 48kHz")

        // Downsample 48kHz → 16kHz (3:1 ratio)
        let downsampleRatio = 3
        var resampled: [Float] = []
        resampled.reserveCapacity(floatSamples.count / downsampleRatio)

        for i in stride(from: 0, to: floatSamples.count, by: downsampleRatio) {
            resampled.append(floatSamples[i])
        }

        print("✓ Resampled to 16kHz: \(resampled.count) samples (\(Double(resampled.count) / 16000.0) seconds)")
        return resampled
    }
}
