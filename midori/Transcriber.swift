//
//  Transcriber.swift
//  midori
//
//  Speech-to-text using FluidAudio/Parakeet V2
//  Uses AudioConverter for proper resampling (no aliasing)
//

import Foundation
import AVFoundation
import FluidAudio

enum TranscriberError: Error {
    case notReady
    case noAudio
    case conversionFailed
    case transcriptionFailed
}

class Transcriber {
    private var asrManager: AsrManager?
    private var audioConverter: AudioConverter?
    private var isReady = false

    init() {
        Task {
            await initialize()
        }
    }

    private func initialize() async {
        do {
            let models = try await AsrModels.downloadAndLoad(version: .v2)
            asrManager = AsrManager(config: .default)
            try await asrManager?.initialize(models: models)
            audioConverter = AudioConverter()
            isReady = true
            print("Transcriber ready")
        } catch {
            print("Failed to initialize transcriber: \(error)")
        }
    }

    func transcribe(buffer: AVAudioPCMBuffer, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let text = try await transcribeAsync(buffer: buffer)
                completion(.success(text))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func transcribeAsync(buffer: AVAudioPCMBuffer) async throws -> String {
        guard isReady, let manager = asrManager, let converter = audioConverter else {
            throw TranscriberError.notReady
        }

        // Use FluidAudio's AudioConverter for proper resampling
        // This handles anti-aliasing correctly (unlike naive stride-3 decimation)
        let samples = try converter.resampleBuffer(buffer)

        guard !samples.isEmpty else {
            throw TranscriberError.noAudio
        }

        let result = try await manager.transcribe(samples)
        let withCorrections = applyDictionaryCorrections(to: result.text)
        return convertNumberWords(in: withCorrections)
    }

    private func applyDictionaryCorrections(to text: String) -> String {
        var result = text

        for entry in DictionaryManager.shared.entries {
            // Case-insensitive word boundary replacement
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: entry.incorrect))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: entry.correct
                )
            }
        }

        return result
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

    private func convertNumberWords(in text: String) -> String {
        // First, expand hyphenated numbers: "seventy-five" → "seventy five"
        var expandedText = text
        for (word, _) in Self.numberWords {
            // Replace "twenty-three" with "twenty three" etc.
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

            // Skip "and" between number words (e.g., "two hundred and sixty-five")
            if word == "and" && hasNumber {
                i += 1
                continue
            }

            // Handle "point" for decimals (e.g., "four point five" → "4.5")
            if word == "point" && hasNumber && i + 1 < words.count {
                // Parse decimal digits after "point"
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
                // Allow standalone multipliers: "hundred" → 100
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
