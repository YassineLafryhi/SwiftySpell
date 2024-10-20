//
//  WordCheckerTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

import XCTest
@testable import SwiftySpellCore

internal class WordCheckerTests: XCTestCase {
    var wordChecker: WordChecker?

    override func setUp() {
        super.setUp()
        wordChecker = WordChecker(
            ignoredWords: ["specialword"],
            ignoredPatternsOfWords: ["test\\d+"],
            ignoredPatternsOfFilesOrDirectories: ["\\.git"])
    }

    func testShouldIgnoreWord() {
        guard let wordChecker = wordChecker else {
            return
        }
        XCTAssertTrue(wordChecker.shouldIgnoreWord(word: "test123"))
        XCTAssertFalse(wordChecker.shouldIgnoreWord(word: "testword"))
        XCTAssertTrue(wordChecker.ignoredWords.contains("specialword"))
    }

    func testCheckAndSuggestCorrections() {
        guard let wordChecker = wordChecker else {
            return
        }

        let word = "testt"
        let corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en"])

        XCTAssertTrue(corrections.keys.contains("testt"))
        XCTAssertTrue(corrections["testt"]?.contains("test") ?? false)
    }

    func testMultipleLanguages() {
        guard let wordChecker = wordChecker else {
            return
        }

        var word = "Thiss"
        var corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en", "fr"])
        XCTAssertTrue(corrections.keys.contains("Thiss"))
        word = "Ceci"
        corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en", "fr"])
        XCTAssertFalse(corrections.keys.contains("Ceci"))
    }

    func testIgnoredWords() {
        guard let wordChecker = wordChecker else {
            return
        }

        let word = "specialword"
        let corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en"])
        XCTAssertFalse(corrections.keys.contains("specialword"))
    }

    func testIgnoredPatterns() {
        guard let wordChecker = wordChecker else {
            return
        }

        var word = "test123"
        var corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en"])
        XCTAssertFalse(corrections.keys.contains("test123"))

        word = "testword"
        corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en"])
        XCTAssertTrue(corrections.keys.contains("testword"))
    }

    func testEmptyWord() {
        guard let wordChecker = wordChecker else {
            return
        }

        let word = ""
        let corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en"])

        XCTAssertTrue(corrections.isEmpty)
    }

    func testCorrectWord() {
        guard let wordChecker = wordChecker else {
            return
        }

        let word = "perfectly"
        let corrections = wordChecker.checkAndSuggestCorrections(word: word, languages: ["en"])

        XCTAssertTrue(corrections.isEmpty)
    }

    func testPerformance() {
        guard let wordChecker = wordChecker else {
            return
        }

        let longText = String(repeating: "word", count: 1_000)

        measure {
            _ = wordChecker.checkAndSuggestCorrections(word: longText, languages: ["en"])
        }
    }
}
