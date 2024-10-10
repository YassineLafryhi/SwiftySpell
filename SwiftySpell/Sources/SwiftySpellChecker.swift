//
//  SwiftySpellChecker.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import AppKit
import Foundation

internal class SwiftySpellChecker {
    var ignoredWords: Set<String> = []
    var ignoredPatternsOfWords: [NSRegularExpression] = []
    var ignoredPatternsOfFilesOrDirectories: [NSRegularExpression] = []

    init(
        ignoredWords: Set<String>,
        ignoredPatternsOfWords: [String],
        ignoredPatternsOfFilesOrDirectories: [String]) {
        self.ignoredWords = ignoredWords
        self.ignoredPatternsOfWords = ignoredPatternsOfWords.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [])
        }
        self.ignoredPatternsOfFilesOrDirectories = ignoredPatternsOfFilesOrDirectories.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [])
        }
    }

    func shouldIgnoreWord(word: String) -> Bool {
        for pattern in ignoredPatternsOfWords {
            let range = NSRange(location: 0, length: word.utf16.count)
            if pattern.firstMatch(in: word, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    func checkAndSuggestCorrections(text: String, languages: Set<String>) -> [String: [String]] {
        // TODO: Use Hunspell for Linux
        let checker = NSSpellChecker.shared
        var corrections: [String: [String]] = [:]
        var searchRange = NSRange(location: 0, length: text.utf16.count)

        while searchRange.location < text.utf16.count {
            var misspelledWordRange: NSRange?
            var misspelledWord = String()
            var isWordMisspelledInAllLanguages = true

            for language in languages {
                let result = checker.checkSpelling(
                    of: text,
                    startingAt: searchRange.location,
                    language: language,
                    wrap: false,
                    inSpellDocumentWithTag: 0,
                    wordCount: nil)

                if result.length > 0 {
                    if misspelledWordRange == nil {
                        misspelledWordRange = NSRange(location: result.location, length: result.length)
                        if let misspelledWordRange = misspelledWordRange {
                            misspelledWord = (text as NSString).substring(with: misspelledWordRange)
                        }
                    }
                } else {
                    isWordMisspelledInAllLanguages = false
                    break
                }
            }

            if !isWordMisspelledInAllLanguages || misspelledWordRange == nil {
                if let range = misspelledWordRange {
                    searchRange.location = range.location + range.length
                } else {
                    searchRange.location = text.utf16.count
                }
                searchRange.length = text.utf16.count - searchRange.location
                continue
            }

            guard let misspelledWordRange = misspelledWordRange else {
                return corrections
            }

            if ignoredWords.contains(misspelledWord) || shouldIgnoreWord(word: misspelledWord) {
                searchRange.location = misspelledWordRange.location + misspelledWordRange.length
                searchRange.length = text.utf16.count - searchRange.location
                continue
            }

            var allSuggestions: Set<String> = []
            for language in languages {
                if
                    let suggestions = checker.guesses(
                        forWordRange: misspelledWordRange,
                        in: text,
                        language: language,
                        inSpellDocumentWithTag: 0) {
                    allSuggestions.formUnion(suggestions)
                }
            }

            if !allSuggestions.isEmpty {
                corrections[misspelledWord] = Array(allSuggestions)
            }
            let correctionsForCurrentWord = corrections[misspelledWord] ?? []
            corrections[misspelledWord] = correctionsForCurrentWord

            searchRange.location = misspelledWordRange.location + misspelledWordRange.length
            searchRange.length = text.utf16.count - searchRange.location
        }
        return corrections
    }
}
