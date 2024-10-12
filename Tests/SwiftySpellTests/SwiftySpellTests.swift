//
//  SwiftySpellTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

import XCTest
@testable import SwiftySpellCore

final class SwiftySpellTests: XCTestCase {
    var swiftySpell: SwiftySpell!
    let testDirectoryPath = FileManager.default.temporaryDirectory.appendingPathComponent("SwiftySpellTests").path

    override func setUp() {
        super.setUp()
        swiftySpell = SwiftySpell()
        try? FileManager.default.createDirectory(atPath: testDirectoryPath, withIntermediateDirectories: true, attributes: nil)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDirectoryPath)
        super.tearDown()
    }

    func testInitCommand() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        DispatchQueue.global().async {
            let result = self.swiftySpell.createConfigFile(at: self.testDirectoryPath)

            let configFilePath = "\(self.testDirectoryPath)/\(Constants.configFileName)"
            XCTAssertTrue(FileManager.default.fileExists(atPath: configFilePath), "Config file should be created")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testLoadConfig() {
        /* let testConfigPath = "\(testDirectoryPath)/\(Constants.configFileName)"
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

         swiftySpell = .init(configFilePath: testDirectoryPath)

         XCTAssertEqual(swiftySpell.config.ignore, ["iOS"])
         XCTAssertEqual(swiftySpell.config.languages, ["en, en_GB"]) */
    }

    func testCheckSpellingForVariables() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forVariables()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            self.swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false, completion: {
                semaphore.signal()
            })
            semaphore.wait()

            let array = self.swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testCheckSpellingForEnumCases() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forEnumCases()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            self.swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false, completion: {
                semaphore.signal()
            })
            semaphore.wait()

            let array = self.swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testCheckSpellingForComments() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forComments()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            self.swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false, completion: {
                semaphore.signal()
            })
            semaphore.wait()

            let array = self.swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testCheckSpellingForClassWithAttributes() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forClassWithAttributes()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            self.swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false, completion: {
                semaphore.signal()
            })
            semaphore.wait()

            let array = self.swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testCheckSpellingForClassWithEnumsAndFunctions() {
        let expectation = expectation(description: "Test SwiftySpellCore")

        let testFilePath = "\(testDirectoryPath)/TestFile.swift"
        let swiftCode = SwiftCodesForTests.forClassWithEnumsAndFunctions()
        let testFileContent = swiftCode.code
        try? testFileContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        DispatchQueue.global().async {
            let semaphore = DispatchSemaphore(value: 0)
            self.swiftySpell.check(self.testDirectoryPath, withFix: false, isRunningFromCLI: false, completion: {
                semaphore.signal()
            })
            semaphore.wait()

            let array = self.swiftySpell.allMisspelledWords.sorted()
            XCTAssertEqual(array, swiftCode.misspelledWords.sorted())

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testFixCommand() {
        // TODO: Implement this Test
    }

    func testLanguagesCommand() {
        // TODO: Implement this Test
    }

    func testRulesCommand() {
        // TODO: Implement this Test
    }

    func testVersionCommand() {
        // TODO: Implement this Test
    }
}
