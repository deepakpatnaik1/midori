//
//  CorrectionLayer.swift
//  midori
//
//  Applies user's custom dictionary corrections and sentence formatting
//

import Foundation

class CorrectionLayer {
    static let shared = CorrectionLayer()

    private let dictionaryManager: DictionaryManager

    // MARK: - Protected Words (Blocklist)

    /// Common English words that should never be "corrected" even if they match a dictionary entry.
    /// Prevents accidental corrections when training creates phonetic collisions
    /// (e.g., "gonna" sounding like "Gunnar").
    private static let protectedWords: Set<String> = [
        // Contractions that sound like names
        "gonna", "wanna", "gotta", "kinda", "sorta", "coulda", "woulda", "shoulda",
        // Common short words that might collide
        "gonna", "done", "come", "some", "one", "won"
    ]

    init(dictionaryManager: DictionaryManager = DictionaryManager.shared) {
        self.dictionaryManager = dictionaryManager
    }

    // MARK: - Main Correction Method

    func applyCorrections(to text: String) -> String {
        var result = text

        // 1. Apply user's custom dictionary
        result = applyUserDictionary(to: result)

        // 2. Apply sentence case
        result = applySentenceCase(to: result)

        return result
    }

    // MARK: - User Dictionary

    private func applyUserDictionary(to text: String) -> String {
        var result = text
        let samples = dictionaryManager.trainingSamples

        // Sort by length (longest first) to handle overlapping corrections
        let sorted = samples.sorted { $0.incorrect.count > $1.incorrect.count }

        for sample in sorted {
            // Skip protected words to prevent phonetic collisions
            if Self.protectedWords.contains(sample.incorrect.lowercased()) {
                continue
            }

            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: sample.incorrect) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            // Use stringByReplacingMatches to replace all occurrences at once
            // (Previous approach had a bug where iterating over matches lost earlier replacements)
            let replacement = sample.correct.trimmingCharacters(in: CharacterSet(charactersIn: ".!?,;:"))
            let range = NSRange(location: 0, length: (result as NSString).length)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: replacement)
        }

        return result
    }

    // MARK: - Sentence Formatting

    private func applySentenceCase(to text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = ""
        var shouldCapitalize = true

        for char in text {
            if shouldCapitalize && char.isLetter {
                result.append(char.uppercased())
                shouldCapitalize = false
            } else {
                result.append(char)
                if char == "." || char == "!" || char == "?" {
                    shouldCapitalize = true
                }
            }
        }

        return result
    }
}
