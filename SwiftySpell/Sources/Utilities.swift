//
//  Utilities.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation

internal class Utilities {
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
            return Constants.supportingTerms.contains(where: term.contains)
        }
        return false
    }

    static func printInColors(_ message: String, color: Constants.ANSIColor = .blue, style: Constants.TextStyle = .bold) {
        if doesTerminalSupportANSIColors() { _ = style == .bold ? ";1m" : "m"
            let coloredMessage =
                "\(color.rawValue)\(style == .bold ? color.rawValue.replace("[0;", "[1;") : color.rawValue)\(message)\(Constants.ANSIColor.reset.rawValue)"
            print(coloredMessage)
        } else {
            print(message)
        }
    }

    static func printWarning(_ string: String) {
        print("\(Constants.Severity.warning): \(string)")
    }

    static func printError(_ string: String) {
        print("\(Constants.Severity.error): \(string)")
    }
}
