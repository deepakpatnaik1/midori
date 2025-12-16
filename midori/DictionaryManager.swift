//
//  DictionaryManager.swift
//  midori
//
//  Manages persistent storage of custom dictionary training samples
//

import Foundation
import Combine

class DictionaryManager: ObservableObject {
    static let shared = DictionaryManager()

    @Published var trainingSamples: [(incorrect: String, correct: String)] = []

    // Alias for Transcriber compatibility
    var entries: [(incorrect: String, correct: String)] { trainingSamples }

    private let userDefaults = UserDefaults.standard
    private let storageKey: String

    init(storageKey: String = "midori_training_samples") {
        self.storageKey = storageKey
        loadSamples()
    }

    func loadSamples() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TrainingSample].self, from: data) {
            trainingSamples = decoded.map { ($0.incorrect, $0.correct) }
            print("✓ Loaded \(trainingSamples.count) training samples from storage")
        }
    }

    func saveSamples() {
        let samples = trainingSamples.map { TrainingSample(incorrect: $0.incorrect, correct: $0.correct) }
        if let encoded = try? JSONEncoder().encode(samples) {
            userDefaults.set(encoded, forKey: storageKey)
            print("✓ Saved \(trainingSamples.count) training samples to storage")
        }
    }

    func addSample(incorrect: String, correct: String) {
        // Normalize only the incorrect variant for matching
        // Keep correct phrase exactly as user typed it (preserves capitalization)
        let normalizedIncorrect = normalizeText(incorrect)
        trainingSamples.append((incorrect: normalizedIncorrect, correct: correct))
        saveSamples()
    }

    /// Normalize text by lowercasing and removing punctuation
    private func normalizeText(_ text: String) -> String {
        return text.lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }

    func removeSample(at index: Int) {
        trainingSamples.remove(at: index)
        saveSamples()
    }

    func clearAll() {
        trainingSamples.removeAll()
        saveSamples()
    }
}

// Codable wrapper for tuple
private struct TrainingSample: Codable {
    let incorrect: String
    let correct: String
}
