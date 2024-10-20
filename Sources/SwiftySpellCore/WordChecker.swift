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

    /*
    func checkAndSuggestCorrections(word: String, languages: Set<String>) -> [String: [String]] {
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
    */
    private func checkWordSpelling(_ word: String, language: String) -> (isMispelled: Bool, suggestionArray: [String]) {
        let spellChecker = NSSpellChecker.shared
        
        let misspelledRange = spellChecker.checkSpelling(of: word,
                                                         startingAt: 0,
                                                         language: language,
                                                         wrap: false,
                                                         inSpellDocumentWithTag: 0,
                                                         wordCount: nil)
        
        guard misspelledRange.location != NSNotFound else {
            return (isMispelled: false, suggestionArray: [])
        }
        
        let suggestions = spellChecker.guesses(forWordRange: NSRange(location: 0, length: word.count), in: word, language: language, inSpellDocumentWithTag: 0) ?? []
        
        return (isMispelled: true, suggestionArray: suggestions)
    }
    
    func checkAndSuggestCorrectionsWithHunspell(text: String, languages: Set<String>) -> [String: [String]] {
        var corrections: [String: [String]] = [:]

        let languageCode = languages.first! == "en" ? "en_US" : languages.first!
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
        
        guard let affixURL = URL(string: affixPath),
              let dictionaryURL = URL(string: dictionaryPath) else {
            return nil
        }
        
        return (affixURL, dictionaryURL)
    }
}
