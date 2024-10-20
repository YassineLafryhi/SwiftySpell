//
//  WordChecker.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import AppKit
import Foundation

internal class WordChecker {
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

    func checkAndSuggestCorrections(word: String, languages: Set<String>) -> [String: [String]] {
        var corrections: [String: [String]] = [:]
        var isMisspelledInAllLanguages = true
        var allSuggestions: [String] = []

        if ignoredWords.contains(word) || shouldIgnoreWord(word: word) {
            return corrections
        }

        for language in languages {
            let result = checkWordSpelling(word, language: language)

            if !result.isMispelled {
                isMisspelledInAllLanguages = false
                break
            } else {
                allSuggestions.append(contentsOf: result.suggestionArray)
            }
        }

        if isMisspelledInAllLanguages {
            corrections[word] = Array(Set(allSuggestions))
        }

        return corrections
    }

    private func checkWordSpelling(_ word: String, language: String) -> (isMispelled: Bool, suggestionArray: [String]) {
        let spellChecker = NSSpellChecker.shared

        let misspelledRange = spellChecker.checkSpelling(
            of: word,
            startingAt: 0,
            language: language,
            wrap: false,
            inSpellDocumentWithTag: 0,
            wordCount: nil)

        guard misspelledRange.location != NSNotFound else {
            return (isMispelled: false, suggestionArray: [])
        }

        let suggestions = spellChecker.guesses(
            forWordRange: NSRange(location: 0, length: word.count),
            in: word,
            language: language,
            inSpellDocumentWithTag: 0) ?? []

        return (isMispelled: true, suggestionArray: suggestions)
    }

    #if os(Linux)
    func checkAndSuggestCorrectionsWithHunspell(text: String, languages: Set<String>) -> [String: [String]] {
        var corrections: [String: [String]] = [:]

        guard let firstLanguage = languages.first else {
            return corrections
        }

        let languageCode = firstLanguage == "en" ? "en_US" : firstLanguage
        let checkResult = checkWord(text, languageCode: languageCode)

        if checkResult.0 {
            let misspelledWord = text
            if ignoredWords.contains(misspelledWord) || shouldIgnoreWord(word: misspelledWord) {
            } else {
                corrections[misspelledWord] = checkResult.1
            }
        }

        return corrections
    }

    private func checkWord(_ word: String, languageCode: String) -> (Bool, [String]) {
        var isMisspelled = false
        var suggestions: [String] = []

        if let (affixURL, dictionaryURL) = generateLanguageFilePaths(languageCode: languageCode) {
            if let hunspell = Hunspell(affixFilePath: affixURL.path(), dictionaryFilePath: dictionaryURL.path()) {
                let isCorrect = hunspell.spell(word)
                if !isCorrect {
                    let theSuggestions = hunspell.suggest(word)
                    isMisspelled = true
                    suggestions = theSuggestions
                }
            } else {
                print("Failed to initialize Hunspell")
            }
        }

        return (isMisspelled, suggestions)
    }

    private func generateLanguageFilePaths(languageCode: String) -> (affixURL: URL, dictionaryURL: URL)? {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

        let baseDirectory = "\(homeDirectory)/Library/Spelling"
        let affixPath = "\(baseDirectory)/\(languageCode).\(Constants.hunspellAffixFileExtension)"
        let dictionaryPath = "\(baseDirectory)/\(languageCode).\(Constants.hunspellDictionaryFileExtension)"

        guard
            let affixURL = URL(string: affixPath),
            let dictionaryURL = URL(string: dictionaryPath) else {
            return nil
        }

        return (affixURL, dictionaryURL)
    }
    #endif
}
