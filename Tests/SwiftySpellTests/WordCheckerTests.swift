//
//  WordCheckerTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

import XCTest
@testable import SwiftySpellCore

final class WordCheckerTests: XCTestCase {
    var wordChecker: WordChecker!

    override func setUp() {
        super.setUp()
        wordChecker = WordChecker(
            ignoredWords: ["specialword"],
            ignoredPatternsOfWords: ["test\\d+"],
            ignoredPatternsOfFilesOrDirectories: ["\\.git"])
    }

    func testShouldIgnoreWord() {
        XCTAssertTrue(wordChecker.shouldIgnoreWord(word: "test123"))
        XCTAssertFalse(wordChecker.shouldIgnoreWord(word: "testword"))
        XCTAssertTrue(wordChecker.ignoredWords.contains("specialword"))
    }

    func testCheckAndSuggestCorrections() {
        let text = "This is a testt of the wordChecker. It should find misspelled words."
        let corrections = wordChecker.checkAndSuggestCorrections(text: text, languages: ["en"])

        XCTAssertTrue(corrections.keys.contains("testt"))
        XCTAssertTrue(corrections["testt"]?.contains("test") ?? false)

        XCTAssertFalse(corrections.keys.contains("wordChecker"))
    }

    func testMultipleLanguages() {
        let text = "Thiss is a test of the wordd Checker. Ceci est un testte."
        let corrections = wordChecker.checkAndSuggestCorrections(text: text, languages: ["en", "fr"])

        XCTAssertTrue(corrections.keys.contains("Thiss"))
        XCTAssertTrue(corrections.keys.contains("wordd"))
        XCTAssertTrue(corrections.keys.contains("testte"))

        XCTAssertFalse(corrections.keys.contains("test"))
        XCTAssertFalse(corrections.keys.contains("Ceci"))
        XCTAssertFalse(corrections.keys.contains("un"))
    }

    func testIgnoredWords() {
        let text = "This specialword should be ignored by the wordChecker."
        let corrections = wordChecker.checkAndSuggestCorrections(text: text, languages: ["en"])

        XCTAssertFalse(corrections.keys.contains("specialword"))
    }

    func testIgnoredPatterns() {
        let text = "This test123 should be ignored, but testword should not."
        let corrections = wordChecker.checkAndSuggestCorrections(text: text, languages: ["en"])

        XCTAssertFalse(corrections.keys.contains("test123"))
        XCTAssertTrue(corrections.keys.contains("testword"))
    }

    func testEmptyText() {
        let text = ""
        let corrections = wordChecker.checkAndSuggestCorrections(text: text, languages: ["en"])

        XCTAssertTrue(corrections.isEmpty)
    }

    func testAllCorrectWords() {
        let text = "This is a perfectly correct sentence."
        let corrections = wordChecker.checkAndSuggestCorrections(text: text, languages: ["en"])

        XCTAssertTrue(corrections.isEmpty)
    }

    func testPerformance() {
        let longText = String(repeating: "This is a test of the wordChecker. ", count: 1000)

        measure {
            _ = wordChecker.checkAndSuggestCorrections(text: longText, languages: ["en"])
        }
    }
}
