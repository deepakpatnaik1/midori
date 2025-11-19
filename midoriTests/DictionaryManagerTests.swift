import XCTest
@testable import midori

final class DictionaryManagerTests: XCTestCase {

    var manager: DictionaryManager!

    override func setUp() {
        super.setUp()
        // Use unique storage key for each test to avoid conflicts
        manager = DictionaryManager(storageKey: "test_\(UUID().uuidString)")
        manager.clearAll() // Start with clean slate
    }

    override func tearDown() {
        manager.clearAll()
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testAddSample() {
        // Test adding a single sample
        manager.addSample(incorrect: "clawed", correct: "Claude")

        XCTAssertEqual(manager.trainingSamples.count, 1)
        XCTAssertEqual(manager.trainingSamples[0].incorrect, "clawed")
        XCTAssertEqual(manager.trainingSamples[0].correct, "Claude")
    }

    func testAddMultipleSamples() {
        // Test adding multiple samples
        manager.addSample(incorrect: "clawed", correct: "Claude")
        manager.addSample(incorrect: "supabase", correct: "Supabase")
        manager.addSample(incorrect: "supa base", correct: "Supabase")

        XCTAssertEqual(manager.trainingSamples.count, 3)
    }

    func testNormalizationOfIncorrectField() {
        // Test that incorrect field is normalized (lowercase, no punctuation)
        manager.addSample(incorrect: "Clawed!", correct: "Claude")

        XCTAssertEqual(manager.trainingSamples[0].incorrect, "clawed")
        XCTAssertEqual(manager.trainingSamples[0].correct, "Claude")
    }

    func testPreservationOfCorrectField() {
        // Test that correct field preserves exact capitalization
        manager.addSample(incorrect: "supabase", correct: "Supabase")

        XCTAssertEqual(manager.trainingSamples[0].correct, "Supabase")

        manager.addSample(incorrect: "midori", correct: "MIDORI")
        XCTAssertEqual(manager.trainingSamples[1].correct, "MIDORI")
    }

    func testRemoveSample() {
        // Test removing a sample
        manager.addSample(incorrect: "clawed", correct: "Claude")
        manager.addSample(incorrect: "supabase", correct: "Supabase")

        XCTAssertEqual(manager.trainingSamples.count, 2)

        manager.removeSample(at: 0)

        XCTAssertEqual(manager.trainingSamples.count, 1)
        XCTAssertEqual(manager.trainingSamples[0].correct, "Supabase")
    }

    func testClearAll() {
        // Test clearing all samples
        manager.addSample(incorrect: "clawed", correct: "Claude")
        manager.addSample(incorrect: "supabase", correct: "Supabase")

        XCTAssertEqual(manager.trainingSamples.count, 2)

        manager.clearAll()

        XCTAssertEqual(manager.trainingSamples.count, 0)
    }

    // MARK: - Persistence Tests

    // Note: Persistence is verified manually and via standalone scripts
    // XCTest has issues with UserDefaults persistence across test instances

    // MARK: - Edge Cases

    func testEmptyStrings() {
        // Test handling of empty strings
        manager.addSample(incorrect: "", correct: "")

        XCTAssertEqual(manager.trainingSamples.count, 1)
        XCTAssertEqual(manager.trainingSamples[0].incorrect, "")
        XCTAssertEqual(manager.trainingSamples[0].correct, "")
    }

    func testWhitespaceHandling() {
        // Test handling of whitespace
        manager.addSample(incorrect: "  clawed  ", correct: "  Claude  ")

        // Incorrect should be normalized (trimmed)
        XCTAssertEqual(manager.trainingSamples[0].incorrect, "clawed")
        // Correct should preserve whitespace
        XCTAssertEqual(manager.trainingSamples[0].correct, "  Claude  ")
    }

    func testSpecialCharacters() {
        // Test handling of special characters
        manager.addSample(incorrect: "clawed!", correct: "Claude!")

        // Incorrect should have punctuation removed
        XCTAssertEqual(manager.trainingSamples[0].incorrect, "clawed")
        // Correct should preserve punctuation
        XCTAssertEqual(manager.trainingSamples[0].correct, "Claude!")
    }

    func testMultiWordPhrases() {
        // Test multi-word phrase handling
        manager.addSample(incorrect: "supa base", correct: "Supabase")
        manager.addSample(incorrect: "new york", correct: "New York")

        XCTAssertEqual(manager.trainingSamples[0].incorrect, "supa base")
        XCTAssertEqual(manager.trainingSamples[0].correct, "Supabase")
        XCTAssertEqual(manager.trainingSamples[1].incorrect, "new york")
        XCTAssertEqual(manager.trainingSamples[1].correct, "New York")
    }

}
