//
//  Constants.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation

internal class Constants {
    static let currentVersion = "0.9.6"
    static let configFileName = ".swiftyspell.yml"

    static let sampleConfig = """
        # Languages to check
        languages:
          - en

        # Directories/Files/Regular expressions to exclude
        exclude:
          - Pods
          - Constants.swift

        # Rules to apply
        rules:
          - one_line_comment
          - multi_line_comment

        # Words/Regular expressions to ignore
        ignore:
          - iOS
        """

    static let swiftKeywords = [
        "associatedtype", "deinit", "fileprivate", "rethrows", "typealias", "fallthrough",
        "nonmutating"
    ]

    static let delimiters = ",.:-;_!`"

    static let blockCommentStart = "/*"
    static let blockCommentEnd = "*/"
    static let singleLineCommentStart = "//"
    static let quoteCharacter = "\""
    static let spaceCharacter = " "
    static let newLineCharacter = "\\n"
    static let tabCharacter = "\\t"
    static let swiftFileExtension = "swift"
    static let regexSymbols = "[.^$*+?()\\[\\]{}|\\\\]"
    static let letSwiftKeyword = "let"
    static let varSwiftKeyword = "var"

    enum MessageType {
        case genericError(_ error: String)
        case configFileCreatedSuccessfully(_ fileName: String)
        case failedToCreateConfigFile(_ fileName: String, _ error: String)
        case configFileNotFound(_ fileName: String)
        case failedToReadFile(_ error: String)
        case wordIsMisspelled(path: String, line: Int, column: Int, severity: Severity, word: String)
        case wordIsMisspelledWithSuggestions(
            path: String,
            line: Int,
            column: Int,
            severity: Severity,
            word: String,
            suggestions: [String])
        case duplicatesInIgnoreList(_ duplicates: Set<String>)
        case capitalizedPairsInIgnoreList(_ pairs: [(String, String)])
        case configLoadingError(_ error: String)
        case unknownRule(_ rule: String)
    }

    static func getMessage(_ message: MessageType) -> String {
        switch message {
        case let .configFileCreatedSuccessfully(fileName):
            "\(fileName) config file has been created successfully."
        case let .configFileNotFound(fileName):
            "Config file \(fileName) not found in the project path nor in the home directory."
        case let .failedToReadFile(error):
            "Failed to read file: \(error)"
        case let .wordIsMisspelled(path: path, line: line, column: column, severity: severity, word: word):
            "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled !"
        case let .wordIsMisspelledWithSuggestions(
            path: path,
            line: line,
            column: column,
            severity: severity,
            word: word,
            suggestions: suggestions):
            "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled, do you mean \(suggestions.map { "'\($0)'" }.joined(separator: ", ")) ?"
        case let .genericError(error):
            "Error: \(error)"
        case let .failedToCreateConfigFile(fileName, error):
            "Error creating \(fileName) config file: \(error)"
        case let .duplicatesInIgnoreList(duplicates):
            "The following words are duplicated in the ignore list and can be removed: \(duplicates.joined(separator: ", "))"
        case let .capitalizedPairsInIgnoreList(pairs):
            "The following word pairs exist in both lowercase and capitalized forms: " +
                pairs.map { "\($0.0) and \($0.1)" }.joined(separator: ", ") +
                ". The lowercase version is sufficient for SwiftySpell."
        case let .configLoadingError(error):
            "Error loading configuration: \(error)"
        case let .unknownRule(rule):
            "Unknown rule: \(rule)"
        }
    }

    static let supportingTerms = [
        "xterm-color", "xterm-256color", "screen", "screen-256color", "ansi", "linux", "vt100"
    ]

    enum ANSIColor: String {
        case black = "\u{001B}[0;30m"
        case red = "\u{001B}[0;31m"
        case green = "\u{001B}[0;32m"
        case yellow = "\u{001B}[0;33m"
        case blue = "\u{001B}[0;34m"
        case magenta = "\u{001B}[0;35m"
        case cyan = "\u{001B}[0;36m"
        case white = "\u{001B}[0;37m"
        case reset = "\u{001B}[0m"
        case teal = "\u{001B}[38;5;6m"
    }

    enum TextStyle {
        case normal
        case bold
    }

    enum Severity: String {
        case error
        case warning
    }
}
