//
//  Utilities.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import SwiftySpellCore

internal class Utilities {
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

    enum PathType {
        case file
        case directory
        case notFound
    }

    static func getPathType(path: String) -> PathType {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return .directory
            } else {
                return .file
            }
        } else {
            return .notFound
        }
    }

    static func doesTerminalSupportANSIColors() -> Bool {
        guard isatty(fileno(stdout)) != 0 else {
            return false
        }
        if let termType = getenv("TERM"), let term = String(utf8String: termType) {
            return Utilities.supportingTerms.contains(where: term.contains)
        }
        return false
    }

    static func print(_ message: String, color: Utilities.ANSIColor = .blue, style: Utilities.TextStyle = .bold) {
        if doesTerminalSupportANSIColors() { _ = style == .bold ? ";1m" : "m"
            let coloredMessage =
                "\(color.rawValue)\(style == .bold ? color.rawValue.replace("[0;", "[1;") : color.rawValue)\(message)\(Utilities.ANSIColor.reset.rawValue)"
            Swift.print(coloredMessage)
        } else {
            Swift.print(message)
        }
    }

    static func printWarning(_ string: String) {
        print("\(Utilities.Severity.warning): \(string)")
    }

    static func printError(_ string: String) {
        print("\(Utilities.Severity.error): \(string)")
    }

    public static func getMessage(_ message: Constants.MessageType) -> String {
        switch message {
        case .projectOrSwiftFilePathDoesNotExist:
            return "The given path does not exist."
        case let .configFileCreatedSuccessfully(fileName):
            return "\(fileName) config file has been created successfully."
        case let .configFileNotFound(fileName):
            return
                "Config file \(fileName) not found in the project path nor in the home directory. Default config will be used."
        case let .failedToReadFile(error):
            return "Failed to read file: \(error)"
        case let .wordIsMisspelled(
            path: path, line: line, column: column, severity: severity, word: word):
            return "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled !"
        case let .wordIsMisspelledWithSuggestions(
            path: path,
            line: line,
            column: column,
            severity: severity,
            word: word,
            suggestions: suggestions):
            return
                "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled, do you mean \(suggestions.map { "'\($0)'" }.joined(separator: ", ")) ?"
        case let .genericError(error):
            return "Error: \(error)"
        case let .failedToCreateConfigFile(fileName, error):
            return "Error creating \(fileName) config file: \(error)"
        case let .duplicatesInIgnoreList(duplicates):
            let isManyWords = duplicates.count > 1
            return
                "The following word\(isManyWords ? "s" : "") \(isManyWords ? "are" : "is") duplicated in the ignore list and can be removed: \(duplicates.joined(separator: ", "))"
        case let .capitalizedPairsInIgnoreList(pairs):
            return "The following word pairs exist in both lowercase and capitalized forms: "
                + pairs.map { "\($0.0) and \($0.1)" }.joined(separator: ", ")
                + ". The lowercase version is sufficient for \(Constants.name)."
        case let .configLoadingError(error):
            return "Error loading configuration: \(error)"
        case let .unknownRule(rule):
            return "Unknown rule: \(rule)"
        case let .doneChecking(misspelledWordsNumber, elapsedTime):
            return
                "Done checking! Found \(misspelledWordsNumber) misspelled words. Processing took \(elapsedTime) seconds."
        case .success:
            return ""
        case .doneCheckingAndCorrecting:
            return ""
        }
    }
}

extension String {
    func replace(_ target: String, _ replacement: String) -> String {
        replacingOccurrences(of: target, with: replacement)
    }
}
