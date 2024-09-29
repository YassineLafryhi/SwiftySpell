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
    var withFix = false

    init(configFilePath: String) {
        config = SwiftySpellConfiguration(configFilePath: configFilePath)
        checker = SwiftySpellChecker(
            ignoredWords: config.ignore,
            ignoredPatternsOfWords: config.ignoredPatternsOfWords,
            ignoredPatternsOfFilesOrDirectories: config.ignoredPatternsOfFilesOrDirectories)
    }

    init() {
        config = SwiftySpellConfiguration()
        checker = SwiftySpellChecker(
            ignoredWords: config.ignore,
            ignoredPatternsOfWords: config.ignoredPatternsOfWords,
            ignoredPatternsOfFilesOrDirectories: config.ignoredPatternsOfFilesOrDirectories)
    }

    func check(_ directoryPath: String, withFix: Bool) {
        self.withFix = withFix
        do {
            let swiftFiles = try fetchSwiftFiles(from: directoryPath)
            for file in swiftFiles {
                try processFile(file)
            }
        } catch {
            print(Constants.getMessage(.genericError(error.localizedDescription)))
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
        if let enumerator = enumerator {
            for case let fileURL as URL in enumerator {
                let isDirectory =
                    (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                if isDirectory {
                    if shouldExclude(directory: fileURL) {
                        enumerator.skipDescendants()
                        continue
                    }
                } else {
                    if
                        fileURL.pathExtension == Constants.swiftFileExtension,
                        !shouldExclude(file: fileURL) {
                        swiftFiles.append(fileURL)
                    }
                }
            }
        }
        return swiftFiles
    }

    private func shouldExclude(file: URL) -> Bool {
        for pattern in config.ignoredPatternsOfFilesOrDirectories
            where file.lastPathComponent.range(of: pattern, options: .regularExpression) != nil {
            return true
        }

        if config.excludedFiles.contains(where: { file.lastPathComponent == $0 }) {
            return true
        }

        return false
    }

    private func shouldExclude(directory: URL) -> Bool {
        // TODO: Use config.ignoredPatternsOfFilesOrDirectories
        config.excludedDirectories.contains { directory.path.contains("\($0)") }
    }

    private func processFile(_ url: URL) throws {
        let sourceFile = try SyntaxParser.parse(url)
        let visitor = SwiftySpellCodeVisitor(viewMode: .all)
        visitor.walk(sourceFile)
        // TODO: Add comment rule check here
        visitor.extractOneLineComments(from: url.path)
        visitor.extractMultiLineComments(from: url.path)

        let sourceLocationConverter = SourceLocationConverter(file: url.path, tree: sourceFile)
        checkSpelling(
            in: visitor,
            filePath: url.path,
            sourceLocationConverter: sourceLocationConverter)
    }

    // TODO: Improve this to use SyntaxRewriter
    private func renameInFile(misspelledWord: String, correctWord: String, filePath: String) -> Bool {
        do {
            var fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
            // TODO: Improve this to replace exactly in line number on the misspelledWord column
            fileContents = fileContents.replace(misspelledWord, correctWord)
            try fileContents.write(toFile: filePath, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    private func checkSpelling(
        in visitor: SwiftySpellCodeVisitor,
        filePath: String,
        sourceLocationConverter: SourceLocationConverter) {
        // TODO: Maybe this is no longer needed
        for (identifier, position, kind) in visitor.globalOrConstantVariables {
            if kind == Constants.letSwiftKeyword || kind == Constants.varSwiftKeyword {
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
            let stringValue = node.description.trim()
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

        if config.rules.contains(.supportOneLineComment) {
            for (comment, line) in visitor.oneLineComments {
                processSpelling(
                    for: comment,
                    startLocation: .init(line: line, column: 1, offset: 0, file: filePath),
                    filePath: filePath,
                    sourceLocationConverter: sourceLocationConverter)
            }
        }

        if config.rules.contains(.supportMultiLineComment) {
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
    }

    private func splitCamelCaseString(_ input: String) -> [String] {
        var words: [String] = []
        var currentWord = String()
        for character in input {
            if character.isUppercase, !currentWord.isEmpty {
                words.append(currentWord)
                currentWord = String(character)
            } else {
                currentWord += String(character)
            }
        }
        if !currentWord.isEmpty {
            words.append(currentWord)
        }
        return words
    }

    private func splitStringByDelimiters(
        _ input: String,
        delimiters: CharacterSet = CharacterSet(charactersIn: Constants.delimiters))
        -> [String] {
        input.components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func joinWords(_ input: String) -> String {
        let separators = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "-"))
        return input.components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .joined()
    }

    private func cleanString(_ input: String) -> String {
        input.remove(Constants.newLineCharacter)
            .remove(Constants.tabCharacter)
    }

    private func isValidURL(_ urlString: String) -> Bool {
        // TODO: Use a Regular Expression to check valid URL
        let urlString = urlString.remove(Constants.quoteCharacter)
        return urlString.starts(with: "http://") || urlString.starts(with: "https://")
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

        var currentWordColumn = column

        var string = string.trimmingCharacters(in: .whitespaces)

        if config.rules.contains(.ignoreUrls), isValidURL(string) {
            return
        }
        string = cleanString(string)

        if string.contains(Constants.spaceCharacter) {
            if string.starts(with: Constants.quoteCharacter) {
                currentWordColumn += 1
            }
            let allWords = string.split(separator: Character(Constants.spaceCharacter))
            for word in allWords {
                let wordParts = splitCamelCaseString(String(word))
                for part in wordParts {
                    let elements = splitStringByDelimiters(part)
                    for element in elements {
                        currentWordColumn = getColumn(
                            line: line, identifier: element, filePath: filePath)
                        checkWord(word: element)
                        // currentWordColumn += word.count
                    }
                }
            }
        } else {
            /* if string.starts(with: "\"") {
                 currentWordColumn += 1
             } */
            let allWords = splitCamelCaseString(string)
            for word in allWords {
                let elements = splitStringByDelimiters(word)
                for element in elements {
                    checkWord(word: element)
                    currentWordColumn += element.count
                }
            }
        }

        func checkWord(word: String) {
            var word = word
            word = word.trimLastNumbers()
            word = word.remove("\(Constants.possessiveApostrophe)\(Constants.possessiveMarker)")
                .remove(Constants.possessiveApostrophe)

            var isMisspelledWordCorrected = false
            let corrections = checker.checkAndSuggestCorrections(
                text: word, languages: config.languages)
            if !corrections.isEmpty {
                for (misspelledWord, suggestions) in corrections {
                    if !withFix, suggestions.isEmpty {
                        print(
                            Constants.getMessage(
                                .wordIsMisspelled(
                                    path: filePath,
                                    line: line,
                                    column: currentWordColumn,
                                    severity: .warning,
                                    word: misspelledWord)))
                    } else {
                        // TODO: For these rules, using the suggestions array is not always sufficient
                        let isIgnoreCapitalizationRuleEnabled = config.rules.contains(.ignoreCapitalization)
                        let isSupportFlatCaseRuleEnabled = config.rules.contains(.supportFlatCase)

                        var shouldCapitalizeWord = false
                        var areWordsInFlatCaseFullyCorrect = false

                        if isSupportFlatCaseRuleEnabled {
                            for suggestion in suggestions {
                                if misspelledWord == joinWords(suggestion) {
                                    areWordsInFlatCaseFullyCorrect = true
                                }

                                // TODO: If the misspelledWord starts with a word from the ignore list, remove it then recheck spelling of the resulting word
                            }
                        }

                        for suggestion in suggestions {
                            if misspelledWord == suggestion.lowercased() {
                                shouldCapitalizeWord = true
                            }
                        }

                        if shouldCapitalizeWord && isIgnoreCapitalizationRuleEnabled {
                            continue
                        }

                        if shouldCapitalizeWord || !areWordsInFlatCaseFullyCorrect {
                            if withFix, suggestions.count == 1, let correctWord = suggestions.first {
                                isMisspelledWordCorrected = renameInFile(
                                    misspelledWord: misspelledWord,
                                    correctWord: correctWord,
                                    filePath: filePath)
                            }
                            if !isMisspelledWordCorrected {
                                print(
                                    Constants.getMessage(
                                        .wordIsMisspelledWithSuggestions(
                                            path: filePath,
                                            line: line,
                                            column: currentWordColumn,
                                            severity: .warning,
                                            word: misspelledWord,
                                            suggestions: suggestions)))
                            }
                        }
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
            Utilities.printError(
                Constants.getMessage(.failedToReadFile(error.localizedDescription)))
        }
        return 1
    }
}
