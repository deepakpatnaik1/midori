//
//  CorrectionLayer.swift
//  midori
//
//  Applies custom dictionary corrections to transcribed text
//

import Foundation

class CorrectionLayer {
    static let shared = CorrectionLayer()

    private let dictionaryManager: DictionaryManager

    init(dictionaryManager: DictionaryManager = DictionaryManager.shared) {
        self.dictionaryManager = dictionaryManager
    }

    /// Applies custom dictionary corrections to transcribed text
    func applyCorrections(to text: String) -> String {
        // Work with original text - preserve all punctuation from Parakeet
        var correctedText = text
        let samples = dictionaryManager.trainingSamples

        // Sort by length (longest first) to handle overlapping matches
        let sortedSamples = samples.sorted { $0.incorrect.count > $1.incorrect.count }

        // For each dictionary entry, find and replace
        // The dictionary stores normalized variants (no punctuation), but we need to
        // match them in the original text while preserving punctuation
        for sample in sortedSamples {
            // Build regex pattern that matches the words with optional punctuation/whitespace between
            let words = sample.incorrect.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

            if words.isEmpty { continue }

            // Create pattern with word boundaries: \bword1\b\s*\p{P}*\s*\bword2\b...
            var pattern = "\\b" // Start with word boundary
            for (index, word) in words.enumerated() {
                pattern += NSRegularExpression.escapedPattern(for: word)
                pattern += "\\b" // End word with boundary
                if index < words.count - 1 {
                    pattern += "\\s*\\p{P}*\\s*\\b" // optional whitespace, punctuation, whitespace, then next word boundary
                }
            }

            // Try to match and replace
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = correctedText as NSString
                let matches = regex.matches(in: correctedText, range: NSRange(location: 0, length: nsString.length))

                // Replace matches in reverse order to maintain string indices
                for match in matches.reversed() {
                    let range = match.range
                    // Strip trailing punctuation from replacement to avoid double punctuation
                    let replacement = sample.correct.trimmingCharacters(in: CharacterSet(charactersIn: ".!?,;:"))
                    correctedText = (correctedText as NSString).replacingCharacters(in: range, with: replacement) as String
                }
            }
        }

        // Apply sentence case to the corrected text
        let sentenceCased = applySentenceCase(to: correctedText)

        return sentenceCased
    }

    /// Apply sentence case: capitalize first letter and letters after sentence-ending punctuation
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
                // Capitalize after sentence-ending punctuation
                if char == "." || char == "!" || char == "?" {
                    shouldCapitalize = true
                }
            }
        }

        return result
    }
}
