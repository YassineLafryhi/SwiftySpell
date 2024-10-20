//
//  SwiftySpellTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

import XCTest
@testable import SwiftySpellCore

internal class SwiftySpellTests: XCTestCase {
    var swiftySpell: SwiftySpell?
    let testDirectoryPath = FileManager.default.temporaryDirectory.appendingPathComponent("SwiftySpellTests").path
    let testTimeout = 5.0

    override func setUp() {
        super.setUp()
        swiftySpell = SwiftySpell()
        guard let swiftySpell = swiftySpell else {
            return
        }
        swiftySpell.setConfig()
        try? FileManager.default.createDirectory(atPath: testDirectoryPath, withIntermediateDirectories: true, attributes: nil)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDirectoryPath)
        super.tearDown()
    }

    func testInitCommand() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        DispatchQueue.global().async {
            let result = swiftySpell.createConfigFile(at: self.testDirectoryPath)

            let configFilePath = "\(self.testDirectoryPath)/\(Constants.configFileName)"
            XCTAssertTrue(FileManager.default.fileExists(atPath: configFilePath), "Config file should be created")

            expectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testLoadConfig() {
        let testConfigPath = "\(testDirectoryPath)/\(Constants.configFileName)"
        let testConfig = """
                    # Languages to check
                    languages:
                      - en
                      - en_GB

                    # Directories/Files/Regular expressions to exclude
                    exclude:
                      - Pods
                      - Constants.swift

                    # Rules to apply
                    rules:
                      - support_flat_case
                      - support_one_line_comment
                      - support_multi_line_comment
                      #- support_british_words
                      #- ignore_capitalization
                      - ignore_swift_keywords
                      - ignore_commonly_used_words
                      #- ignore_shortened_words
                      #- ignore_lorem_ipsum
                      #- ignore_html_tags
                      - ignore_urls

                    # Words/Regular expressions to ignore
                    ignore:
                      - iOS
            """
        try? testConfig.write(toFile: testConfigPath, atomically: true, encoding: .utf8)

        guard let swiftySpell = swiftySpell else {
            return
        }

        swiftySpell.setConfig(configFilePath: testConfigPath)

        guard let config = swiftySpell.config else {
            return
        }

        XCTAssertTrue(config.ignore.contains("iOS"))
        XCTAssertEqual(config.languages, ["en", "en_GB"])
    }

    func testCheckSpellingForVariables() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forVariables()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForStrings() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forStrings()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForEnumCases() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forEnumCases()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForComments() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forComments()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForClassWithAttributes() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forClassWithAttributes()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForClassWithEnumsAndFunctions() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forClassWithEnumsAndFunctions()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testCheckSpellingForManyCodeSegments() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forManyCodeSegments()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let array = swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testFixCommand() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        guard let swiftySpell = swiftySpell else {
            return
        }

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forVariables()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            swiftySpell.check(self.testDirectoryPath, withFix: true, isRunningFromCLI: false) {
                semaphore.signal()
            }
            semaphore.wait()

            let fileContent = try? String(contentsOfFile: testFilePath)
            XCTAssertEqual(fileContent, swiftCode.code.replace(swiftCode.misspelledWords[0], swiftCode.correctedWords[0]))

            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testLanguagesCommand() {
        guard let swiftySpell = swiftySpell else {
            return
        }

        let languages = swiftySpell.getSupportedLanguages()
        XCTAssertNotNil(languages)
    }

    func testRulesCommand() {
        guard let swiftySpell = swiftySpell else {
            return
        }

        let rules = swiftySpell.getSupportedRules()
        XCTAssertNotNil(rules)
    }

    func testVersionCommand() {
        guard let swiftySpell = swiftySpell else {
            return
        }

        let version = swiftySpell.getCurrentVersion()
        XCTAssertNotNil(version)
    }
}
