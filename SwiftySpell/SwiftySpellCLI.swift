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
        for pattern in config.excludePatterns
            where file.lastPathComponent.range(of: pattern, options: .regularExpression) != nil {
            return true
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
        visitor.extractOneLineComments(from: url.path)
        visitor.extractMultiLineComments(from: url.path)

        let sourceLocationConverter = SourceLocationConverter(file: url.path, tree: sourceFile)
        checkSpelling(in: visitor, filePath: url.path, sourceLocationConverter: sourceLocationConverter)
    }

    private func checkSpelling(
        in visitor: SwiftySpellCodeVisitor,
        filePath: String,
        sourceLocationConverter: SourceLocationConverter) {
        // TODO: Maybe this is no longer needed
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

        for node in visitor.enums {
            let enumName = node.identifier.text
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: enumName,
                startLocation: startLocation,
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

        for (associatedValue, position) in visitor.enumCasesAssociatedValues {
            processSpelling(
                for: associatedValue,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.strings {
            let stringValue = node.description.trimmingCharacters(in: .whitespacesAndNewlines)
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: stringValue,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.classes {
            let className = node.identifier.text
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: className,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (aStruct, position) in visitor.structs {
            processSpelling(
                for: aStruct,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.functions {
            let functionName = node.identifier.text
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: functionName,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.genericTypeParameters {
            let paramName = node.name.text
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: paramName,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.attributes {
            let attributeName = node.attributeName.text
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: attributeName,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.customOperators {
            let operatorName = node.identifier.text
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: operatorName,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (guardStatementsVariable, position) in visitor.guardStatementsVariables {
            processSpelling(
                for: guardStatementsVariable,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (guardStatementsValue, position) in visitor.guardStatementsValues {
            processSpelling(
                for: guardStatementsValue,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.subscripts {
            for parameter in node.indices.parameterList {
                let paramName = parameter.firstName?.text ?? parameter.secondName?.text ?? ""
                if !paramName.isEmpty {
                    let startLocation = parameter.startLocation(converter: sourceLocationConverter)
                    processSpelling(
                        for: paramName,
                        startLocation: startLocation,
                        filePath: filePath,
                        sourceLocationConverter: sourceLocationConverter)
                }

                if let type = parameter.type {
                    let typeName = type.description.trimmingCharacters(in: .whitespaces)
                    let startLocation = type.startLocation(converter: sourceLocationConverter)
                    processSpelling(
                        for: typeName,
                        startLocation: startLocation,
                        filePath: filePath,
                        sourceLocationConverter: sourceLocationConverter)
                }
            }

            let returnClause = node.result
            let returnTypeName = returnClause.returnType.description.trimmingCharacters(
                in: .whitespaces)
            let startLocation = returnClause.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: returnTypeName,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (dictionaryKey, position) in visitor.dictionaryKeys {
            processSpelling(
                for: dictionaryKey,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (dictionaryValue, position) in visitor.dictionaryValues {
            processSpelling(
                for: dictionaryValue,
                position: position,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for (comment, line) in visitor.oneLineComments {
            processSpelling(
                for: comment,
                startLocation: .init(line: line, column: 1, offset: 0, file: filePath),
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for multiLineComment in visitor.multiLineComments {
            for (commentLine, line) in multiLineComment {
                processSpelling(
                    for: commentLine,
                    startLocation: .init(line: line, column: 1, offset: 0, file: filePath),
                    filePath: filePath,
                    sourceLocationConverter: sourceLocationConverter)
            }
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
        for string: String,
        position: AbsolutePosition? = nil,
        startLocation: SourceLocation? = nil,
        filePath: String,
        sourceLocationConverter: SourceLocationConverter) {
        let line: Int
        var column: Int
        if let position = position {
            let sourceLocation = sourceLocationConverter.location(for: position)
            line = sourceLocation.line ?? 0
            column = sourceLocation.column ?? 0
        } else {
            line = startLocation?.line ?? 0
            column = getColumn(line: line, identifier: string, filePath: filePath)
        }

        // TODO: Remove this check and use a Regex instead (configurable in the config file)
        if string.starts(with: "eyJ") {
            return // JWT tokens
        }

        var currentWordColumn = column

        if string.contains(" ") {
            if string.starts(with: "\"") {
                currentWordColumn += 1
            }
            let allWords = string.split(separator: " ")
            for word in allWords {
                currentWordColumn = getColumn(
                    line: line, identifier: String(word), filePath: filePath)
                checkWord(word: String(word))
                // currentWordColumn += word.count
            }
        } else {
            /* if string.starts(with: "\"") {
                 currentWordColumn += 1
             } */
            let allWords = splitCamelCaseString(string)
            for word in allWords {
                checkWord(word: word)
                currentWordColumn += word.count
            }
        }

        func checkWord(word: String) {
            let corrections = checker.checkAndSuggestCorrections(
                text: word, languages: config.languages)
            if !corrections.isEmpty {
                for (misspelledWord, suggestions) in corrections {
                    if suggestions.isEmpty {
                        print(
                            "\(filePath):\(line):\(currentWordColumn): warning: '\(misspelledWord)' may be misspelled !")
                    } else {
                        print(
                            "\(filePath):\(line):\(currentWordColumn): warning: '\(misspelledWord)' may be misspelled, do you mean \(suggestions.map { "'\($0)'" }.joined(separator: ", ")) ?")
                    }
                }
            }
        }
    }

    private func getColumn(line: Int, identifier: String, filePath: String) -> Int {
        do {
            let fileContent = try String(contentsOfFile: filePath)
            let lines = fileContent.components(separatedBy: .newlines)
            let lineContent = lines[line - 1]
            let index =
                lineContent.range(of: identifier)?.lowerBound.utf16Offset(in: lineContent) ?? 0
            return index + 1
        } catch {
            Utilities.printError("Failed to read file: \(error)")
        }
        return 1
    }
}
