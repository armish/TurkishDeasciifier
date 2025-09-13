#!/usr/bin/env swift

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
        "ç": "c", "Ç": "c", "ğ": "g", "Ğ": "g", "ı": "i", "İ": "i",
        "ö": "o", "Ö": "o", "ş": "s", "Ş": "s", "ü": "u", "Ü": "u"
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
            print("⚠️ Error loading patterns: \(error)")
        }
        
        return [:]
    }()
    
    func debugCharacter(_ char: Character, at point: Int, in text: [Character], expected: Character) {
        print("🔍 DEBUGGING CHARACTER AT POSITION \(point)")
        print("Character: '\(char)' -> Expected: '\(expected)'")
        print("Context around position: '\(String(text[max(0, point-5)..<min(text.count, point+6)]))'")
        
        let tr = turkishAsciifyTable[char] ?? char
        print("ASCII equivalent: '\(tr)'")
        
        guard let patternList = Self.completePatterns[Character(tr.lowercased())] else {
            print("❌ No patterns found for character '\(tr.lowercased())'")
            return
        }
        
        print("✅ Found \(patternList.count) patterns for '\(tr.lowercased())'")
        
        let contextStr = turkishGetContext(size: turkishContextSize, at: point, in: text)
        print("Swift context: '\(contextStr)'")
        
        let match = turkishMatchPattern(patternList, at: point, in: text)
        print("Pattern match result: \(match)")
        
        let needsCorrection = turkishNeedCorrection(char, at: point, in: text)
        print("Needs correction: \(needsCorrection)")
        
        if needsCorrection {
            let converted = turkishToggleAccent(char)
            print("Swift converts: '\(char)' → '\(converted)'")
            if converted == expected {
                print("✅ CORRECT")
            } else {
                print("❌ WRONG - Expected: '\(expected)'")
            }
        } else {
            print("Swift does NOT convert")
            if char == expected {
                print("✅ CORRECT (no conversion needed)")
            } else {
                print("❌ WRONG - Should convert to: '\(expected)'")
            }
        }
        print(String(repeating: "-", count: 60))
    }
    
    func convertToTurkish(_ text: String) -> String {
        let textArray = Array(text)
        var result = textArray
        
        for i in 0..<textArray.count {
            let char = textArray[i]
            if turkishNeedCorrection(char, at: i, in: textArray) {
                result[i] = turkishToggleAccent(char)
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
        
        if tr == "I" {
            return char == tr ? match : !match
        } else {
            return char == tr ? match : !match
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
                    if abs(r) > abs(rank) {
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

// Load reference result for comparison
let referenceResult: String
do {
    referenceResult = try String(contentsOfFile: "Tests/comprehensive_result.txt", encoding: .utf8)
} catch {
    print("❌ Could not load reference result file. Run reference comparison first.")
    exit(1)
}

// Test text
let testText = """
Turkiye, resmi adiyla Turkiye Cumhuriyeti, topraklarinin buyuk bolumu Bati Asya'da Anadolu'da, diger bir bolumu ise Guneydogu Avrupa'nin uzantisi Dogu Trakya'da olan kitalararasi bir ulkedir. Batida Bulgaristan ve Yunanistan, doguda Gurcistan, Ermenistan, Iran ve Azerbaycan, guneyde ise Irak ve Suriye ile sinir komsusudur. Guneyini Kibris ve Akdeniz, batisini Ege Denizi, kuzeyini ise Karadeniz cevreler. Marmara Denizi ise Istanbul Bogazi ve Canakkale Bogazi ile birlikte Anadolu'yu Trakya'dan, yani Asya'yi Avrupa'dan ayirir. Resmi olarak laik bir devlet olan Turkiye'de nufusun cogunlugu Muslumandir. Ankara, Turkiye'nin baskenti ve ikinci en kalabalik sehri; Istanbul ise, Turkiye'nin en kalabalik sehri, ekonomik merkezi ve ayni zamanda Avrupa'nin en kalabalik sehridir.

Cumhuriyet, siyasi gucun halk ve temsilcileri tarafindan paylasildigi bir devlet yonetim seklidir ve yapisi geregi monarsinin yoklugu uzerine kuruludur. Bir cumhuriyette temsil, genel vatandaslar tarafindan serbestce secilebilir veya secimle belirlenebilir. Bircok tarihi cumhuriyette, temsil kisisel statuye dayanmis ve secimlerin rolu sinirli olmustur. Bu durum gunumuzde de gecerlidir; resmi adlarinda "cumhuriyet" kelimesini kullanan 159 devlet (2017 itibariyla) ve diger cumhuriyet olarak kurulmus devletler, temsil hakkini ve secim surecini dar bir sekilde sinirlayan devletler arasinda yer almaktadir. Bu terim, MO 509'da krallarin devrilmesinden MS 27'de Imparatorlugun kurulmasina kadar suren Antik Roma Cumhuriyeti'nin anayasasina atifta bulunarak modern anlamini gelistirmistir. Bu anayasa, etkili bir sekilde guc sahibi olan zengin soylulardan olusan bir Senato; magistralari secme ve yasalari kabul etme yetkisine sahip tum ozgur vatandaslarin katildigi birkac halk meclisi; ve cesitli turde sivil ve siyasi yetkilere sahip bir dizi magistratliktan olusuyordu. Genellikle bir cumhuriyet tek bir egemen devlet olsa da, cumhuriyet olarak adlandirilan alt ulusal devlet varliklari veya dogasi geregi cumhuriyetci olarak tanimlanan hukumetler de bulunmaktadir.

Bilim veya ilim, nedensellik, merak ve amac besleyen, olgulari ve iddialari deney, gozlem ve dusunce araciligiyla sistematik bir sekilde inceleyen entelektuel ve uygulamali disiplinler butunudur. Bilimi siniflandiran bilim felsefecileri bilimi formal bilimler, sosyal bilimler ve doga bilimleri olmak uzere uce ayirir. Bilimin diger tum dallardan en ayirt edici ozelligi, savunmalarini somut kanitlarla sunmasidir. Bu sayede bilim, bilinmeyen olgulari aciklamamiza ve evreni idrak etmemize guclu destek olur.
"""

print("🐛 ACCURACY DEBUGGING - SWIFT VS REFERENCE")
print(String(repeating: "=", count: 80))

let deasciifier = TurkishDeasciifier()
let swiftResult = deasciifier.convertToTurkish(testText)

let inputChars = Array(testText)
let referenceChars = Array(referenceResult)
let swiftChars = Array(swiftResult)

print("Analyzing first 10 discrepancies where reference succeeds but Swift fails...")
print("")

var debugCount = 0
for i in 0..<min(inputChars.count, referenceChars.count) {
    let input = inputChars[i]
    let reference = referenceChars[i]
    let swift = i < swiftChars.count ? swiftChars[i] : input
    
    // Find cases where reference converts correctly but Swift doesn't
    if input != reference && swift != reference && debugCount < 10 {
        deasciifier.debugCharacter(input, at: i, in: inputChars, expected: reference)
        debugCount += 1
    }
}

print("\n📊 OVERALL RESULTS:")
var referenceConversions = 0
var swiftMatches = 0

for i in 0..<inputChars.count {
    let input = inputChars[i]
    let reference = i < referenceChars.count ? referenceChars[i] : input
    let swift = i < swiftChars.count ? swiftChars[i] : input
    
    if reference != input {
        referenceConversions += 1
        if swift == reference {
            swiftMatches += 1
        }
    }
}

let accuracy = referenceConversions > 0 ? Double(swiftMatches) / Double(referenceConversions) * 100 : 0
print("Reference conversions: \(referenceConversions)")
print("Swift matches: \(swiftMatches)")  
print("Current accuracy: \(String(format: "%.2f", accuracy))%")
print("Target: 98%+ (need to fix \(referenceConversions - swiftMatches) more cases)")