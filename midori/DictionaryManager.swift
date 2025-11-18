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

    private let userDefaults = UserDefaults.standard
    private let storageKey = "midori_training_samples"

    private init() {
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
        trainingSamples.append((incorrect: incorrect, correct: correct))
        saveSamples()
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
