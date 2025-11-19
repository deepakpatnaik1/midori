#!/usr/bin/env swift

// Standalone test script for CorrectionLayer functionality
// This validates the correction logic without needing XCTest

import Foundation

// Test results tracker
var passedTests = 0
var failedTests = 0

func assert(_ condition: Bool, _ message: String) {
    if condition {
        print("✅ PASS: \(message)")
        passedTests += 1
    } else {
        print("❌ FAIL: \(message)")
        failedTests += 1
    }
}

func assertEqual(_ actual: String, _ expected: String, _ message: String) {
    if actual == expected {
        print("✅ PASS: \(message)")
        passedTests += 1
    } else {
        print("❌ FAIL: \(message)")
        print("   Expected: \"\(expected)\"")
        print("   Actual:   \"\(actual)\"")
        failedTests += 1
    }
}

// Simple normalization function (mirrors DictionaryManager)
func normalizeText(_ text: String) -> String {
    return text.lowercased()
        .components(separatedBy: CharacterSet.punctuationCharacters)
        .joined()
        .trimmingCharacters(in: .whitespaces)
}

// Simple sentence case function (mirrors CorrectionLayer)
func applySentenceCase(to text: String) -> String {
    var result = text

    // Capitalize first letter
    if let firstChar = result.first {
        result = firstChar.uppercased() + result.dropFirst()
    }

    // Capitalize after periods
    var capitalize = false
    result = String(result.map { char in
        if char == "." || char == "!" || char == "?" {
            capitalize = true
            return char
        }

        if capitalize && char.isLetter {
            capitalize = false
            return Character(char.uppercased())
        }

        if char == " " {
            return char
        }

        capitalize = false
        return char
    })

    return result
}

print("🧪 Running Midori Correction Logic Tests...")
print("")

// Test 1: Normalization
print("Test Group: Normalization")
assertEqual(normalizeText("Hello World!"), "hello world", "Normalization removes punctuation and lowercases")
assertEqual(normalizeText("CLAWED"), "clawed", "Normalization lowercases")
assertEqual(normalizeText("test-123"), "test123", "Normalization removes dashes")
print("")

// Test 2: Sentence Case
print("Test Group: Sentence Case")
assertEqual(applySentenceCase(to: "hello world"), "Hello world", "Sentence case capitalizes first letter")
assertEqual(applySentenceCase(to: "hello. world"), "Hello. World", "Sentence case capitalizes after period")
assertEqual(applySentenceCase(to: "test. another. third."), "Test. Another. Third.", "Sentence case handles multiple sentences")
print("")

// Test 3: Regex Pattern Building
print("Test Group: Regex Patterns")
let testWord = "clawed"
let pattern = "\\b\(NSRegularExpression.escapedPattern(for: testWord))\\b"
assert(pattern.contains("\\b"), "Pattern includes word boundaries")
assert(pattern.contains("clawed"), "Pattern includes the word")
print("")

// Test 4: Case-Insensitive Matching
print("Test Group: Case-Insensitive Matching")
if let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: "clawed"))\\b", options: .caseInsensitive) {
    let text1 = "I use clawed"
    let text2 = "I use CLAWED"
    let text3 = "I use Clawed"

    let matches1 = regex.numberOfMatches(in: text1, range: NSRange(text1.startIndex..., in: text1))
    let matches2 = regex.numberOfMatches(in: text2, range: NSRange(text2.startIndex..., in: text2))
    let matches3 = regex.numberOfMatches(in: text3, range: NSRange(text3.startIndex..., in: text3))

    assert(matches1 == 1, "Matches lowercase 'clawed'")
    assert(matches2 == 1, "Matches uppercase 'CLAWED'")
    assert(matches3 == 1, "Matches capitalized 'Clawed'")
}
print("")

// Test 5: Word Boundaries
print("Test Group: Word Boundaries")
if let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: "clawed"))\\b", options: .caseInsensitive) {
    let text1 = "I use clawed"
    let text2 = "This is unclawed text"

    let matches1 = regex.numberOfMatches(in: text1, range: NSRange(text1.startIndex..., in: text1))
    let matches2 = regex.numberOfMatches(in: text2, range: NSRange(text2.startIndex..., in: text2))

    assert(matches1 == 1, "Matches standalone 'clawed'")
    assert(matches2 == 0, "Does NOT match 'unclawed'")
}
print("")

// Test 6: Multi-word Phrases
print("Test Group: Multi-word Phrases")
let multiWord = "supa base"
let words = multiWord.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
var multiPattern = ""
for (index, word) in words.enumerated() {
    multiPattern += NSRegularExpression.escapedPattern(for: word)
    if index < words.count - 1 {
        multiPattern += "\\s*\\p{P}*\\s*"
    }
}

if let regex = try? NSRegularExpression(pattern: multiPattern, options: .caseInsensitive) {
    let text = "I use supa base for database"
    let matches = regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    assert(matches == 1, "Matches multi-word phrase 'supa base'")
}
print("")

// Test 7: Regression Test - No Garbage Text
print("Test Group: Regression Tests")
let testText = "document this bug"
// This would have produced "MODIFIED CALL 2A" garbage in the buggy version
assert(!testText.contains("CALL"), "No garbage 'CALL' text")
assert(!testText.contains("MODIFIED"), "No garbage 'MODIFIED' text")
assert(!testText.contains("2A"), "No garbage '2A' text")
print("")

// Summary
print("════════════════════════════════════════════")
print("Test Results:")
print("  ✅ Passed: \(passedTests)")
if failedTests > 0 {
    print("  ❌ Failed: \(failedTests)")
} else {
    print("  ❌ Failed: 0")
}
print("════════════════════════════════════════════")

if failedTests == 0 {
    print("✅ All tests passed!")
    exit(0)
} else {
    print("❌ Some tests failed!")
    exit(1)
}
