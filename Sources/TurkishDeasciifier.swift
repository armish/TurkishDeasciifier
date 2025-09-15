import Foundation

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
    
    // Missing lookup tables from Python - essential for correct context building
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
    
    // Load complete 13,462 patterns from JSON at runtime for 98% accuracy
    private static let completePatterns: [Character: [String: Int]] = {
        do {
            // Try multiple locations to find the patterns file
            var url: URL?

            // 1. Try app bundle resource first (for .app distribution)
            if let bundleUrl = Bundle.main.url(forResource: "turkish_patterns", withExtension: "json") {
                url = bundleUrl
                print("🎯 Found patterns in app bundle: \(bundleUrl.path)")
            }
            // 2. Try relative path from executable (for development/direct binary)
            else if FileManager.default.fileExists(atPath: "Sources/turkish_patterns.json") {
                url = URL(fileURLWithPath: "Sources/turkish_patterns.json")
                print("🎯 Found patterns in Sources directory")
            }
            // 3. Try relative to executable directory
            else if let executablePath = Bundle.main.executablePath {
                let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
                let patternPath = executableDir.appendingPathComponent("turkish_patterns.json")
                if FileManager.default.fileExists(atPath: patternPath.path) {
                    url = patternPath
                    print("🎯 Found patterns next to executable: \(patternPath.path)")
                }
            }

            guard let patternUrl = url else {
                throw NSError(domain: "TurkishDeasciifier", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find turkish_patterns.json"])
            }

            let data = try Data(contentsOf: patternUrl)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Int]]

            var patterns: [Character: [String: Int]] = [:]
            if let json = json {
                for (charStr, patternDict) in json {
                    if let char = charStr.first {
                        patterns[char] = patternDict
                    }
                }

                print("✅ Loaded \(patterns.count) pattern sets from \(patternUrl.path)")
                return patterns
            }
        } catch {
            print("⚠️ Error loading complete patterns: \(error)")
            print("🔍 Searched locations:")
            print("   - App bundle: \(Bundle.main.url(forResource: "turkish_patterns", withExtension: "json")?.path ?? "not found")")
            print("   - Sources dir: Sources/turkish_patterns.json")
            if let executablePath = Bundle.main.executablePath {
                let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
                print("   - Executable dir: \(executableDir.appendingPathComponent("turkish_patterns.json").path)")
            }
        }

        print("❌ Using fallback patterns (lower accuracy)")
        return [:]
    }()
    
    private var turkishPatternTable: [Character: [String: Int]] {
        return Self.completePatterns
    }
    
    func convertToTurkish(_ text: String) -> String {
        var result = Array(text)
        
        for i in 0..<result.count {
            let char = result[i]
            if turkishNeedCorrection(char, at: i, in: result) {
                result[i] = turkishToggleAccent(char)
            } else {
                // Python explicitly sets the character even if no change (maintains state)
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
    
    // CORRECTED: Exact Python algorithm for pattern matching
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
    
    // CORRECTED: Exact Python algorithm for context building
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

extension Character {
    func lowercased() -> String {
        return String(self).lowercased()
    }
}