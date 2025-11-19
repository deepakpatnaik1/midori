import XCTest
@testable import midori

final class CorrectionLayerTests: XCTestCase {

    var correctionLayer: CorrectionLayer!
    var dictionaryManager: DictionaryManager!

    override func setUp() {
        super.setUp()
        // Use unique storage key for each test to avoid conflicts
        dictionaryManager = DictionaryManager(storageKey: "test_\(UUID().uuidString)")
        dictionaryManager.clearAll()
        correctionLayer = CorrectionLayer(dictionaryManager: dictionaryManager)
    }

    override func tearDown() {
        dictionaryManager.clearAll()
        super.tearDown()
    }

    // MARK: - Basic Correction Tests

    func testSimpleCorrection() {
        // Test basic word replacement
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let input = "I use clawed for AI assistance."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "I use Claude for AI assistance.")
    }

    func testCaseInsensitiveMatching() {
        // Test that matching is case-insensitive
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let input1 = "I use clawed every day."
        let output1 = correctionLayer.applyCorrections(to: input1)
        XCTAssertEqual(output1, "I use Claude every day.")

        let input2 = "I use CLAWED every day."
        let output2 = correctionLayer.applyCorrections(to: input2)
        XCTAssertEqual(output2, "I use Claude every day.")

        let input3 = "I use Clawed every day."
        let output3 = correctionLayer.applyCorrections(to: input3)
        XCTAssertEqual(output3, "I use Claude every day.")
    }

    func testWordBoundaries() {
        // Test that word boundaries are respected
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        // "clawed" should match
        let input1 = "I use clawed."
        let output1 = correctionLayer.applyCorrections(to: input1)
        XCTAssertEqual(output1, "I use Claude.")

        // "unclawed" should NOT match
        let input2 = "This is unclawed text."
        let output2 = correctionLayer.applyCorrections(to: input2)
        XCTAssertEqual(output2, "This is unclawed text.")
    }

    func testMultiWordPhrases() {
        // Test multi-word phrase corrections
        dictionaryManager.addSample(incorrect: "supa base", correct: "Supabase")

        let input = "I use supa base for my database."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "I use Supabase for my database.")
    }

    func testMultipleCorrections() {
        // Test multiple corrections in one text
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")
        dictionaryManager.addSample(incorrect: "supabase", correct: "Supabase")

        let input = "I use clawed and supabase together."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "I use Claude and Supabase together.")
    }

    func testRepeatedWords() {
        // Test correction of repeated words
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let input = "clawed is great. I love clawed. clawed rocks!"
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "Claude is great. I love Claude. Claude rocks!")
    }

    // MARK: - Punctuation Tests

    func testPunctuationPreservation() {
        // Test that punctuation is preserved
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let input1 = "I use clawed."
        let output1 = correctionLayer.applyCorrections(to: input1)
        XCTAssertEqual(output1, "I use Claude.")

        let input2 = "Do you use clawed?"
        let output2 = correctionLayer.applyCorrections(to: input2)
        XCTAssertEqual(output2, "Do you use Claude?")

        let input3 = "I love clawed!"
        let output3 = correctionLayer.applyCorrections(to: input3)
        XCTAssertEqual(output3, "I love Claude!")
    }

    func testPunctuationInMiddle() {
        // Test words with punctuation in the middle
        dictionaryManager.addSample(incorrect: "dont", correct: "don't")

        let input = "I dont know."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "I don't know.")
    }

    // MARK: - Sentence Case Tests

    func testSentenceCase() {
        // Test that sentence case is applied
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let input = "i use clawed. it is great. i love it."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "I use Claude. It is great. I love it.")
    }

    func testSentenceCaseWithMultipleSentences() {
        // Test sentence case with multiple sentences
        let input = "hello world. this is a test. another sentence here."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "Hello world. This is a test. Another sentence here.")
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        // Test with empty input
        let output = correctionLayer.applyCorrections(to: "")
        XCTAssertEqual(output, "")
    }

    func testNoCorrections() {
        // Test with no corrections defined
        let input = "This is normal text."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "This is normal text.")
    }

    func testNoMatches() {
        // Test with corrections defined but no matches
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let input = "This text has no matching words."
        let output = correctionLayer.applyCorrections(to: input)

        XCTAssertEqual(output, "This text has no matching words.")
    }

    func testOverlappingPhrases() {
        // Test handling of overlapping phrases
        // Note: Current implementation processes longest matches first but may have overlapping replacements
        dictionaryManager.addSample(incorrect: "new york", correct: "New York")

        let input = "I live in new york city."
        let output = correctionLayer.applyCorrections(to: input)

        // "new york" should be matched as a phrase
        XCTAssertEqual(output, "I live in New York city.")
    }

    // MARK: - Regression Tests for Known Bugs

    func testNoPunctuationCorruption() {
        // REGRESSION TEST: Test for the "MODIFIED CALL 2A" bug
        // This was a critical bug where text became corrupted with inserted garbage
        dictionaryManager.addSample(incorrect: "document", correct: "Document")

        let input = "document this bug. document this bug. document this bug."
        let output = correctionLayer.applyCorrections(to: input)

        // Should NOT contain any garbage like "MODIFIED CALL 2A" or "Call 2A"
        XCTAssertFalse(output.contains("CALL"), "Output should not contain garbage text")
        XCTAssertFalse(output.contains("MODIFIED"), "Output should not contain garbage text")
        XCTAssertFalse(output.contains("2A"), "Output should not contain garbage text")

        // Should be clean corrected text
        XCTAssertEqual(output, "Document this bug. Document this bug. Document this bug.")
    }

    func testNoWordFragmentation() {
        // REGRESSION TEST: Test that words don't get fragmented
        dictionaryManager.addSample(incorrect: "test", correct: "TEST")

        let input = "This is a test of the system."
        let output = correctionLayer.applyCorrections(to: input)

        // Words should remain intact, not fragmented
        let words = output.split(separator: " ")
        XCTAssertEqual(words.count, 7, "Should have exactly 7 words")
    }

    // MARK: - Performance Tests

    func testPerformanceWithManyCorrections() {
        // Test performance with many corrections
        for i in 1...100 {
            dictionaryManager.addSample(incorrect: "word\(i)", correct: "WORD\(i)")
        }

        let input = "This is word50 in the middle of text with word99 at the end."

        measure {
            _ = correctionLayer.applyCorrections(to: input)
        }
    }

    func testPerformanceWithLongText() {
        // Test performance with long text
        dictionaryManager.addSample(incorrect: "clawed", correct: "Claude")

        let longText = String(repeating: "I use clawed for AI assistance. ", count: 100)

        measure {
            _ = correctionLayer.applyCorrections(to: longText)
        }
    }

    // MARK: - Integration Tests

    func testEndToEndWorkflow() {
        // Test complete workflow: add sample, apply correction
        dictionaryManager.addSample(incorrect: "supabase", correct: "Supabase")

        // Simulate what Parakeet might transcribe
        let parakeetOutput = "supabase is the database I use. The database I use is supabase."

        // Apply corrections
        let correctedOutput = correctionLayer.applyCorrections(to: parakeetOutput)

        // Verify all instances are corrected
        XCTAssertTrue(correctedOutput.contains("Supabase"))
        XCTAssertFalse(correctedOutput.contains("supabase"))
        XCTAssertEqual(correctedOutput, "Supabase is the database I use. The database I use is Supabase.")
    }
}
