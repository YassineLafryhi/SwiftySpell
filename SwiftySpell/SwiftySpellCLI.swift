//
//  SwiftySpellCLI.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser

internal class SwiftySpellCLI {
    let fileManager = FileManager.default
    let config: SwiftySpellConfiguration
    let checker: SwiftySpellChecker

    init(configFilePath: String) {
        config = SwiftySpellConfiguration(configFilePath: configFilePath)
        checker = SwiftySpellChecker(ignoreList: config.ignoreList, excludePatterns: config.excludePatterns)
    }

    func run(for directoryPath: String) {
        do {
            let swiftFiles = try fetchSwiftFiles(from: directoryPath)
            for file in swiftFiles {
                try processFile(file)
            }
        } catch {
            print("Error: \(error)")
        }
    }

    private func fetchSwiftFiles(from directory: String) throws -> [URL] {
        let directoryURL = URL(fileURLWithPath: directory)
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]

        let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants])

        var swiftFiles = [URL]()
        for case let fileURL as URL in enumerator! {
            let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDirectory {
                if shouldExclude(directory: fileURL) {
                    enumerator?.skipDescendants()
                    continue
                }
            } else {
                if fileURL.pathExtension == "swift", !shouldExclude(file: fileURL) {
                    swiftFiles.append(fileURL)
                }
            }
        }
        return swiftFiles
    }

    private func shouldExclude(file: URL) -> Bool {
        for pattern in config.excludePatterns {
            if file.lastPathComponent.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        if config.excludeFiles.contains(where: { file.lastPathComponent == $0 }) {
            return true
        }

        return false
    }

    private func shouldExclude(directory: URL) -> Bool {
        config.excludeDirectories.contains { directory.path.contains("\($0)") }
    }

    private func processFile(_ url: URL) throws {
        let sourceFile = try SyntaxParser.parse(url)
        let visitor = SwiftySpellCodeVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        let sourceLocationConverter = SourceLocationConverter(file: url.path, tree: sourceFile)
        checkSpelling(in: visitor, filePath: url.path, sourceLocationConverter: sourceLocationConverter)
    }

    private func checkSpelling(
        in visitor: SwiftySpellCodeVisitor,
        filePath: String,
        sourceLocationConverter: SourceLocationConverter) {
        for (identifier, position, kind) in visitor.globalOrConstantVariables {
            if kind == "let" || kind == "var" {
                processSpelling(
                    for: identifier,
                    position: position,
                    filePath: filePath,
                    sourceLocationConverter: sourceLocationConverter)
            }
        }

        for (variable, position) in visitor.variables {
            processSpelling(
                for: variable,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (paramName, position) in visitor.functionParameters {
            processSpelling(
                for: paramName,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (extendedTypeName, position) in visitor.extensions {
            processSpelling(
                for: extendedTypeName,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (protocolName, position) in visitor.protocols {
            processSpelling(
                for: protocolName,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (typeName, position) in visitor.typeAliases {
            processSpelling(
                for: typeName,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (enumName, position) in visitor.enums {
            processSpelling(
                for: enumName,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (caseName, position) in visitor.enumCases {
            processSpelling(
                for: caseName,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (string, position) in visitor.strings {
            let trimmedString = string.trimmingCharacters(in: .whitespaces)

            let words = trimmedString.contains(" ") ? trimmedString.split(separator: " ") : [Substring(trimmedString)]

            for word in words {
                let trimmedWord = word.trimmingCharacters(in: .whitespaces)

                if !trimmedWord.isEmpty {
                    processSpelling(
                        for: trimmedWord,
                        position: position,
                        filePath: filePath,
                        sourceLocationConverter: sourceLocationConverter)
                }
            }
        }

        for (aClass, position) in visitor.classes {
            processSpelling(for: aClass, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }

        for (aStruct, position) in visitor.structs {
            processSpelling(
                for: aStruct,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (function, position) in visitor.functions {
            processSpelling(
                for: function,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }
    }

    func splitCamelCaseString(_ input: String) -> [String] {
        var words: [String] = []
        var currentWord = ""
        for character in input {
            if character.isUppercase, !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = String(character) /* .lowercased() */
            } else {
                currentWord += String(character)
            }
        }
        if !currentWord.isEmpty {
            words.append(currentWord)
        }
        return words
    }

    private func processSpelling(
        for word: String,
        position: AbsolutePosition,
        filePath: String,
        sourceLocationConverter: SourceLocationConverter) {
        let sourceLocation = sourceLocationConverter.location(for: position)
        let line = sourceLocation.line ?? 0
        let column = sourceLocation.column ?? 0

        if word.starts(with: "eyJ") {
            return // JWT tokens
        }
        let allWords = splitCamelCaseString(word)

        for aWord in allWords {
            let corrections = checker.checkAndSuggestCorrections(text: aWord, languages: config.languages)
            if !corrections.isEmpty {
                for (misspelledWord, suggestions) in corrections {
                    if suggestions.isEmpty {
                        print(
                            "\(filePath):\(line):\(column): warning: '\(misspelledWord)' may be misspelled !")
                    } else {
                        print(
                            "\(filePath):\(line):\(column): warning: '\(misspelledWord)' may be misspelled, do you mean \(suggestions.map { "'\($0)'" }.joined(separator: ", ")) ?")
                    }
                }
            }
        }
    }
}
