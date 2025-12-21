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

            // Apply corrections
            let correctedText = CorrectionLayer.shared.applyCorrections(to: result.text)
            print("✓ Applied corrections")

            // Convert number words to digits (with "one" context protection)
            let withNumbers = self.convertNumberWords(in: correctedText)
            print("✓ Converted number words to digits")

            DispatchQueue.main.async {
                completion(.success(withNumbers))
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

    // MARK: - Number Word Conversion

    private static let numberWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
        "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
        "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90
    ]

    private static let multipliers: [String: Int] = [
        "hundred": 100, "thousand": 1000, "million": 1_000_000, "billion": 1_000_000_000
    ]

    // Words before "one" that indicate it should stay as word
    private static let oneBeforeContext = ["that", "this", "which", "the", "another", "each", "every", "any", "some", "no", "change", "pick", "choose", "select", "find", "get", "want", "need", "have", "see", "only"]

    // Words after "one" that indicate it should stay as word
    private static let oneAfterContext = ["of", "more", "less", "thing", "time", "way", "reason", "person", "day", "who", "that", "which"]

    private func shouldKeepOneAsWord(words: [String], at index: Int) -> Bool {
        let beforeWord = index > 0 ? words[index - 1].lowercased().trimmingCharacters(in: .punctuationCharacters) : ""
        let afterWord = index < words.count - 1 ? words[index + 1].lowercased().trimmingCharacters(in: .punctuationCharacters) : ""

        // Check if preceding or following word indicates "one" should stay as word
        if Self.oneBeforeContext.contains(beforeWord) {
            return true
        }
        if Self.oneAfterContext.contains(afterWord) {
            return true
        }

        return false
    }

    private func convertNumberWords(in text: String) -> String {
        // Expand hyphenated numbers: "seventy-five" → "seventy five"
        var expandedText = text
        for (word, _) in Self.numberWords {
            let hyphenPattern = "(?i)\\b(\(word))-(\\w+)\\b"
            if let regex = try? NSRegularExpression(pattern: hyphenPattern) {
                expandedText = regex.stringByReplacingMatches(
                    in: expandedText,
                    range: NSRange(expandedText.startIndex..., in: expandedText),
                    withTemplate: "$1 $2"
                )
            }
        }

        let words = expandedText.components(separatedBy: .whitespaces)
        var result: [String] = []
        var i = 0

        while i < words.count {
            let word = words[i]
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)

            // Special handling for "one" - check context before converting
            if cleanWord == "one" && shouldKeepOneAsWord(words: words, at: i) {
                result.append(word)  // Keep as "one"
                i += 1
                continue
            }

            let (numberStr, consumed) = parseNumberSequence(from: words, startingAt: i)

            if let num = numberStr, consumed > 0 {
                result.append(num)
                i += consumed
            } else {
                result.append(words[i])
                i += 1
            }
        }

        return result.joined(separator: " ")
    }

    private func parseNumberSequence(from words: [String], startingAt start: Int) -> (String?, Int) {
        var total = 0
        var current = 0
        var consumed = 0
        var hasNumber = false
        var decimalPart: String? = nil

        var i = start
        while i < words.count {
            let word = words[i].lowercased().trimmingCharacters(in: .punctuationCharacters)

            // Skip "and" between number words
            if word == "and" && hasNumber {
                i += 1
                continue
            }

            // Handle "point" for decimals
            if word == "point" && hasNumber && i + 1 < words.count {
                var decimalDigits = ""
                var j = i + 1
                while j < words.count {
                    let nextWord = words[j].lowercased().trimmingCharacters(in: .punctuationCharacters)
                    if let value = Self.numberWords[nextWord], value < 10 {
                        decimalDigits += String(value)
                        j += 1
                    } else {
                        break
                    }
                }
                if !decimalDigits.isEmpty {
                    decimalPart = decimalDigits
                    consumed = j - start
                    i = j
                    break
                }
            }

            if let value = Self.numberWords[word] {
                hasNumber = true
                if value < 100 {
                    current += value
                }
                consumed = i - start + 1
                i += 1
            } else if let mult = Self.multipliers[word] {
                hasNumber = true
                if mult == 100 {
                    current = (current == 0 ? 1 : current) * mult
                } else {
                    current = (current == 0 ? 1 : current) * mult
                    total += current
                    current = 0
                }
                consumed = i - start + 1
                i += 1
            } else {
                break
            }
        }

        total += current

        if hasNumber {
            if let decimal = decimalPart {
                return ("\(total).\(decimal)", consumed)
            }
            return (String(total), consumed)
        }
        return (nil, 0)
    }
}
