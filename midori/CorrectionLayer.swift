//
//  CorrectionLayer.swift
//  midori
//
//  Correction layer with pre-built dev vocabulary and context checks
//

import Foundation

/// A correction rule with context awareness
struct Correction {
    let mishearings: [String]       // What Parakeet might output: ["clawed", "claud"]
    let correction: String          // What we want: "Claude"
    let positiveContext: [String]   // Apply when these words nearby (empty = always check negative)
    let negativeContext: [String]   // DON'T apply when these words nearby
    let requiresContext: Bool       // If true, needs positive context to apply

    init(mishearings: [String], correction: String, positiveContext: [String] = [], negativeContext: [String] = [], requiresContext: Bool = false) {
        self.mishearings = mishearings.map { $0.lowercased() }
        self.correction = correction
        self.positiveContext = positiveContext.map { $0.lowercased() }
        self.negativeContext = negativeContext.map { $0.lowercased() }
        self.requiresContext = requiresContext
    }
}

class CorrectionLayer {
    static let shared = CorrectionLayer()

    private let dictionaryManager: DictionaryManager

    // Context window: how many words before/after to check
    private let contextWindow = 8

    // MARK: - Pre-built Vocabulary (from user's actual training data)

    private let builtInCorrections: [Correction] = [
        // ===== AI/ML =====
        Correction(
            mishearings: ["claude", "cloud", "clawed", "clod"],
            correction: "Claude",
            positiveContext: ["ai", "api", "anthropic", "model", "chat", "assistant", "ask", "said", "says", "told"],
            negativeContext: [],
            requiresContext: false  // Common enough to always correct
        ),

        // ===== Names (require stricter context) =====
        Correction(
            mishearings: ["gonna", "ghana", "gunner", "gunnar", "donna"],
            correction: "Gunnar",
            positiveContext: ["said", "says", "asked", "told", "ask", "tell", "with", "from", "hey", "hi", "dear"],
            negativeContext: ["i'm", "im", "i am", "we're", "were", "you're", "youre", "they're", "theyre", "going to", "want to", "have to", "need to", "try to", "able to"],
            requiresContext: true  // Names need positive context
        ),
        Correction(
            mishearings: ["deepak", "deepuck", "deepuk", "debuck", "debeck"],
            correction: "Deepak",
            positiveContext: ["said", "says", "asked", "name", "by", "from", "author", "written", "patnaik"],
            negativeContext: [],
            requiresContext: false  // First name, apply freely
        ),
        Correction(
            mishearings: ["but nike", "patnaik", "butnyk"],
            correction: "Patnaik",
            positiveContext: ["deepak", "said", "says", "asked", "name", "by", "from", "author"],
            negativeContext: [],
            requiresContext: false  // Last name, apply freely
        ),
        Correction(
            mishearings: ["alessia", "alicia", "alicja"],
            correction: "Alicja",
            positiveContext: ["said", "says", "asked", "told", "ask", "tell", "with", "from", "hey", "hi"],
            negativeContext: [],
            requiresContext: true
        ),

        // ===== Dev Platforms (always apply) =====
        Correction(
            mishearings: ["super bass", "superbass", "supabase", "superbase", "suba base", "subabase", "super base"],
            correction: "Supabase",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["for sale", "wassel", "vercel"],
            correction: "Vercel",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["get hub", "git hub", "gith ub"],
            correction: "GitHub",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["coop", "cube", "kube", "kuber netties", "cooper netties"],
            correction: "Kubernetes",
            positiveContext: ["cluster", "pod", "container", "deploy", "k8s"],
            negativeContext: [],
            requiresContext: false
        ),

        // ===== File types =====
        Correction(
            mishearings: ["dot mdfile", "dot md file", "md file"],
            correction: ".md file",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["claude md", "claude dot mt"],
            correction: "Claude.md",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["docs md"],
            correction: "docs.md",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),

        // ===== Doc/Docs disambiguation =====
        Correction(
            mishearings: ["dock"],
            correction: "doc",
            positiveContext: ["file", "markdown", "readme", "documentation", "write", "read", "open", "edit", "the", "a"],
            negativeContext: ["docker", "container", "image", "kubernetes", "k8s", "pod", "deploy", "compose", "build"],
            requiresContext: false
        ),
        Correction(
            mishearings: ["dogs", "ducks", "docks"],
            correction: "docs",
            positiveContext: [],
            negativeContext: ["docker", "container", "image", "animal", "pet"],
            requiresContext: false
        ),

        // ===== Projects =====
        Correction(
            mishearings: ["eater", "ether", "aether", "ato"],
            correction: "Aether",
            positiveContext: ["project", "app", "build", "run", "the", "in", "for"],
            negativeContext: ["or", "neither", "whether", "food", "eat"],
            requiresContext: true
        ),
        Correction(
            mishearings: ["asura", "azora", "azura", "a soda", "asuda", "asoda"],
            correction: "Asura",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["a soda workflow stock", "asura workflows doc", "asura workflow stock"],
            correction: "Asura workflows doc",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),

        // ===== UI Terms =====
        Correction(
            mishearings: ["columns", "duns", "turns", "terms"],
            correction: "turns",
            positiveContext: ["message", "chat", "conversation"],
            negativeContext: [],
            requiresContext: true  // Too generic, needs context
        ),
        Correction(
            mishearings: ["cadusl", "carusal", "carousel", "caruso", "carousal"],
            correction: "carousel",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),

        // ===== Domains =====
        Correction(
            mishearings: ["ubar", "uvar", "ovar", "ouvar", "oovarai", "kuvar"],
            correction: "oovar.ai",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
        Correction(
            mishearings: ["honey bloom", "honeybloomco", "honeybloom", "honeybloomcoco"],
            correction: "honeybloom.co",
            positiveContext: [],
            negativeContext: [],
            requiresContext: false
        ),
    ]

    init(dictionaryManager: DictionaryManager = DictionaryManager.shared) {
        self.dictionaryManager = dictionaryManager
    }

    // MARK: - Main Correction Method

    func applyCorrections(to text: String) -> String {
        var result = text

        // 1. Apply built-in vocabulary corrections (context-aware)
        result = applyBuiltInCorrections(to: result)

        // 2. Apply user's custom dictionary
        result = applyUserDictionary(to: result)

        // 3. Apply sentence case
        // Note: Number formatting is handled in TranscriptionManager with "one" context protection
        result = applySentenceCase(to: result)

        return result
    }

    // MARK: - Built-in Corrections

    private func applyBuiltInCorrections(to text: String) -> String {
        var result = text
        let words = tokenize(text)

        for correction in builtInCorrections {
            result = applyCorrection(correction, to: result, words: words)
        }

        return result
    }

    private func applyCorrection(_ correction: Correction, to text: String, words: [String]) -> String {
        var result = text

        for mishearing in correction.mishearings {
            // Find all occurrences of this mishearing
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: mishearing) + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }

            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))

            // Process matches in reverse to maintain indices
            for match in matches.reversed() {
                let matchRange = match.range
                let matchStart = matchRange.location

                // Get context words around this match
                let contextWords = getContextWords(around: matchStart, in: result, window: contextWindow)

                // Check if we should apply this correction
                let shouldApply = shouldApplyCorrection(correction, contextWords: contextWords)

                if shouldApply {
                    result = nsString.replacingCharacters(in: matchRange, with: correction.correction)
                }
            }
        }

        return result
    }

    private func shouldApplyCorrection(_ correction: Correction, contextWords: [String]) -> Bool {
        let contextLower = contextWords.map { $0.lowercased() }

        // Check negative context first - if any match, don't apply
        for negative in correction.negativeContext {
            // Check for multi-word negative patterns
            let negativeWords = negative.components(separatedBy: " ")
            if negativeWords.count > 1 {
                // Check if the phrase exists in context
                let contextString = contextLower.joined(separator: " ")
                if contextString.contains(negative) {
                    return false
                }
            } else {
                if contextLower.contains(negative) {
                    return false
                }
            }
        }

        // If requires positive context, check for it
        if correction.requiresContext {
            for positive in correction.positiveContext {
                if contextLower.contains(positive) {
                    return true
                }
            }
            return false  // Required context but none found
        }

        // Doesn't require context and no negative context matched
        return true
    }

    private func getContextWords(around position: Int, in text: String, window: Int) -> [String] {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Find which word index contains this position
        var charCount = 0
        var wordIndex = 0
        for (i, word) in words.enumerated() {
            charCount += word.count + 1  // +1 for space
            if charCount > position {
                wordIndex = i
                break
            }
        }

        // Get words in window
        let start = max(0, wordIndex - window)
        let end = min(words.count, wordIndex + window + 1)

        return Array(words[start..<end])
    }

    // MARK: - User Dictionary

    private func applyUserDictionary(to text: String) -> String {
        var result = text
        let samples = dictionaryManager.trainingSamples

        // Sort by length (longest first)
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

    // MARK: - Utilities

    private func tokenize(_ text: String) -> [String] {
        return text.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
    }

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
