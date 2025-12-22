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
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: sample.incorrect) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))

            for match in matches.reversed() {
                let replacement = sample.correct.trimmingCharacters(in: CharacterSet(charactersIn: ".!?,;:"))
                result = nsString.replacingCharacters(in: match.range, with: replacement)
            }
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
