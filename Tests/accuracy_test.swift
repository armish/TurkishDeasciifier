#!/usr/bin/env swift

import Foundation

// Standalone accuracy test that verifies 98%+ accuracy
// This test will exit with code 1 if accuracy drops below 98%

struct TurkishDeasciifier {
    private let turkishContextSize = 10
    
    private let turkishAsciifyTable: [Character: Character] = [
        "ç": "c", "Ç": "C",
        "ğ": "g", "Ğ": "G", 
        "ö": "o", "Ö": "O",
        "ü": "u", "Ü": "U",
        "ı": "i", "İ": "I",
        "ş": "s", "Ş": "S"
    ]
    
    private let turkishToggleAccentTable: [Character: Character] = [
        "c": "ç", "C": "Ç",
        "g": "ğ", "G": "Ğ",
        "o": "ö", "O": "Ö",
        "u": "ü", "U": "Ü",
        "i": "ı", "I": "İ",
        "s": "ş", "S": "Ş",
        "ç": "c", "Ç": "C",
        "ğ": "g", "Ğ": "G",
        "ö": "o", "Ö": "O",
        "ü": "u", "Ü": "U",
        "ı": "i", "İ": "I",
        "ş": "s", "Ş": "S"
    ]
    
    private let turkishDowncaseAsciifyTable: [Character: Character] = [
        "A": "a", "a": "a", "B": "b", "b": "b", "C": "c", "c": "c", "D": "d", "d": "d",
        "E": "e", "e": "e", "F": "f", "f": "f", "G": "g", "g": "g", "H": "h", "h": "h",
        "I": "i", "i": "i", "J": "j", "j": "j", "K": "k", "k": "k", "L": "l", "l": "l",
        "M": "m", "m": "m", "N": "n", "n": "n", "O": "o", "o": "o", "P": "p", "p": "p",
        "Q": "q", "q": "q", "R": "r", "r": "r", "S": "s", "s": "s", "T": "t", "t": "t",
        "U": "u", "u": "u", "V": "v", "v": "v", "W": "w", "w": "w", "X": "x", "x": "x",
        "Y": "y", "y": "y", "Z": "z", "z": "z",
        "ç": "c", "Ç": "c", "ğ": "g", "Ğ": "g", "ı": "i", "İ": "i",
        "ö": "o", "Ö": "o", "ş": "s", "Ş": "s", "ü": "u", "Ü": "u"
    ]
    
    private let turkishUpcaseAccentsTable: [Character: Character] = [
        "A": "a", "a": "a", "B": "b", "b": "b", "C": "c", "c": "c", "D": "d", "d": "d",
        "E": "e", "e": "e", "F": "f", "f": "f", "G": "g", "g": "g", "H": "h", "h": "h",
        "I": "i", "i": "i", "J": "j", "j": "j", "K": "k", "k": "k", "L": "l", "l": "l",
        "M": "m", "m": "m", "N": "n", "n": "n", "O": "o", "o": "o", "P": "p", "p": "p",
        "Q": "q", "q": "q", "R": "r", "r": "r", "S": "s", "s": "s", "T": "t", "t": "t",
        "U": "u", "u": "u", "V": "v", "v": "v", "W": "w", "w": "w", "X": "x", "x": "x",
        "Y": "y", "y": "y", "Z": "z", "z": "z",
        "ç": "C", "Ç": "C", "ğ": "G", "Ğ": "G", "ı": "I", "İ": "i",
        "ö": "O", "Ö": "O", "ş": "S", "Ş": "S", "ü": "U", "Ü": "U"
    ]
    
    // Load complete 13,462 patterns from JSON file
    private static let completePatterns: [Character: [String: Int]] = {
        do {
            let url = URL(fileURLWithPath: "Sources/turkish_patterns.json")
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Int]]
            
            var patterns: [Character: [String: Int]] = [:]
            if let json = json {
                for (charStr, patternDict) in json {
                    if let char = charStr.first {
                        patterns[char] = patternDict
                    }
                }
                return patterns
            }
        } catch {
            print("❌ Error loading patterns: \(error)")
        }
        
        return [:]
    }()
    
    func convertToTurkish(_ text: String) -> String {
        var result = Array(text)
        
        for i in 0..<result.count {
            let char = result[i]
            if turkishNeedCorrection(char, at: i, in: result) {
                result[i] = turkishToggleAccent(char)
            } else {
                result[i] = char
            }
        }
        
        return String(result)
    }
    
    private func turkishNeedCorrection(_ char: Character, at point: Int, in text: [Character]) -> Bool {
        let tr = turkishAsciifyTable[char] ?? char
        
        guard let patternList = Self.completePatterns[Character(tr.lowercased())] else {
            return false
        }
        
        let match = turkishMatchPattern(patternList, at: point, in: text)
        
        // Special case for I character - matches Python logic exactly
        if String(tr) == "I" {
            if char == tr {
                return !match  // If original char is 'I', return NOT match
            } else {
                return match   // If original char is 'İ', return match
            }
        } else {
            if char == tr {
                return match   // For other chars, if original equals ASCII, return match
            } else {
                return !match  // If original is accented, return NOT match
            }
        }
    }
    
    private func turkishMatchPattern(_ patternDict: [String: Int], at point: Int, in text: [Character]) -> Bool {
        var rank = 2 * patternDict.count  // Initialize rank like Python
        let contextStr = turkishGetContext(size: turkishContextSize, at: point, in: text)
        var start = 0
        let _len = contextStr.count
        
        while start <= turkishContextSize {
            var end = 1 + turkishContextSize
            while end <= _len {
                let startIdx = contextStr.index(contextStr.startIndex, offsetBy: start)
                let endIdx = contextStr.index(contextStr.startIndex, offsetBy: end)
                let pattern = String(contextStr[startIdx..<endIdx])
                
                if let r = patternDict[pattern], r != 0 {
                    if abs(r) < abs(rank) {
                        rank = r
                    }
                }
                end = end + 1
            }
            start = start + 1
        }
        
        return rank > 0
    }
    
    private func turkishGetContext(size: Int, at point: Int, in text: [Character]) -> String {
        // Step 1: Create string of spaces like Python
        var s = String(repeating: " ", count: 1 + (2 * size))
        
        // Step 2: Set middle character to 'X'
        let midIndex = s.index(s.startIndex, offsetBy: size)
        s.replaceSubrange(midIndex...midIndex, with: "X")
        
        var i = 1 + size
        var space = false
        var index = point
        
        // Step 3: Process characters FORWARD from point + 1
        index = point + 1
        
        while i < s.count && !space && index < text.count {
            let currentChar = text[index]
            let x = turkishDowncaseAsciifyTable[currentChar]
            
            if x == nil {
                if !space {
                    i = i + 1
                    space = true
                }
            } else {
                let charIndex = s.index(s.startIndex, offsetBy: i)
                s.replaceSubrange(charIndex...charIndex, with: String(x!))
                i = i + 1
                space = false
            }
            index = index + 1
        }
        
        // Truncate forward part
        s = String(s.prefix(i))
        
        // Step 4: Process characters BACKWARD from point - 1
        index = point
        i = size - 1
        space = false
        index = index - 1
        
        while i >= 0 && index >= 0 {
            let currentChar = text[index]
            let x = turkishUpcaseAccentsTable[currentChar]
            
            if x == nil {
                if !space {
                    i = i - 1
                    space = true
                }
            } else {
                let charIndex = s.index(s.startIndex, offsetBy: i)
                s.replaceSubrange(charIndex...charIndex, with: String(x!))
                i = i - 1
                space = false
            }
            index = index - 1
        }
        
        return s
    }
    
    private func turkishToggleAccent(_ char: Character) -> Character {
        return turkishToggleAccentTable[char] ?? char
    }
}

// Test cases with known inputs and expected outputs
struct TestCase {
    let input: String
    let expected: String
    let description: String
}

let testCases = [
    TestCase(
        input: "Turkiye",
        expected: "Türkiye",
        description: "Simple country name"
    ),
    TestCase(
        input: "Istanbul",
        expected: "İstanbul",
        description: "City name with capital I"
    ),
    TestCase(
        input: "Ankara",
        expected: "Ankara",
        description: "No conversion needed"
    ),
    TestCase(
        input: "Turkiye'nin baskenti",
        expected: "Türkiye'nin başkenti",
        description: "Possessive and word combination"
    ),
    TestCase(
        input: "buyuk",
        expected: "büyük",
        description: "Common adjective"
    ),
    TestCase(
        input: "guzel",
        expected: "güzel",
        description: "Common adjective"
    ),
    TestCase(
        input: "tesekkur ederim",
        expected: "teşekkür ederim",
        description: "Thank you phrase"
    ),
    TestCase(
        input: "dogru",
        expected: "doğru",
        description: "Word with ğ"
    ),
    TestCase(
        input: "cok",
        expected: "çok",
        description: "Very common word"
    ),
    TestCase(
        input: "guc",
        expected: "güç",
        description: "Multiple conversions"
    ),
    TestCase(
        input: "universitelerin",
        expected: "üniversitelerin",
        description: "Long word with prefix"
    ),
    TestCase(
        input: "ogrenci",
        expected: "öğrenci",
        description: "Student - common word"
    ),
    TestCase(
        input: "Turk",
        expected: "Türk",
        description: "Nationality"
    ),
    TestCase(
        input: "dusunce",
        expected: "düşünce",
        description: "Thought - multiple conversions"
    ),
    TestCase(
        input: "Ataturk",
        expected: "Atatürk",
        description: "Proper name"
    )
]

// Run tests
print("🧪 TURKISH DEASCIIFIER ACCURACY TEST")
print("=====================================")
print("Running \(testCases.count) test cases...")
print("")

let deasciifier = TurkishDeasciifier()
var passed = 0
var failed = 0
var failedTests: [TestCase] = []

for testCase in testCases {
    let result = deasciifier.convertToTurkish(testCase.input)
    if result == testCase.expected {
        print("✅ PASS: \(testCase.description)")
        print("   '\(testCase.input)' → '\(result)'")
        passed += 1
    } else {
        print("❌ FAIL: \(testCase.description)")
        print("   Input:    '\(testCase.input)'")
        print("   Expected: '\(testCase.expected)'")
        print("   Got:      '\(result)'")
        failed += 1
        failedTests.append(testCase)
    }
}

// Calculate accuracy
let total = passed + failed
let accuracy = total > 0 ? (Double(passed) / Double(total)) * 100.0 : 0.0

print("")
print("=====================================")
print("📊 RESULTS:")
print("   Passed: \(passed)/\(total)")
print("   Failed: \(failed)/\(total)")
print("   Accuracy: \(String(format: "%.1f", accuracy))%")
print("")

// Determine pass/fail based on 98% threshold
let minimumAccuracy = 98.0
if accuracy >= minimumAccuracy {
    print("✅ TEST PASSED: Accuracy \(String(format: "%.1f", accuracy))% meets minimum requirement of \(minimumAccuracy)%")
    exit(0)
} else {
    print("❌ TEST FAILED: Accuracy \(String(format: "%.1f", accuracy))% is below minimum requirement of \(minimumAccuracy)%")
    
    if !failedTests.isEmpty {
        print("")
        print("Failed test cases:")
        for testCase in failedTests {
            print("  - \(testCase.description): '\(testCase.input)' should be '\(testCase.expected)'")
        }
    }
    
    exit(1)
}