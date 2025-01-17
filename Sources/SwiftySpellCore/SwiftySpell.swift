//
//  SwiftySpell.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import AppKit
import Foundation
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

public class SwiftySpell {
    private let fileManager = FileManager.default
    private var checker: WordChecker?
    private var withFix = false
    public var allMisspelledWords: [String] = []
    public var config: Configuration?
    public var misspelledWordsNumber = 0
    public var correctedWordsNumber = 0

    public typealias CompletionHandler = () -> Void

    private var completionHandler: CompletionHandler?

    public init() {}

    public func setConfig(configFilePath: String? = nil) {
        if let configFilePath = configFilePath {
            config = Configuration(configFilePath: configFilePath)
        } else {
            config = Configuration()
        }

        if let config = config {
            checker = WordChecker(
                ignoredWords: config.ignore,
                ignoredPatternsOfWords: config.ignoredPatternsOfWords,
                ignoredPatternsOfFilesOrDirectories: config.ignoredPatternsOfFilesOrDirectories)
        }
    }

    public func getCurrentVersion() -> String {
        Constants.currentVersion
    }

    public func getSupportedLanguages() -> [String] {
        NSSpellChecker.shared.availableLanguages
    }

    public func getSupportedRules() -> [String] {
        Configuration.SupportedRule.allCases.map { $0.rawValue }
    }

    public func createConfigFile(at currentPath: String) -> Constants.MessageType {
        do {
            let filePath = "\(currentPath)/\(Constants.configFileName)"
            try Constants.sampleConfig.write(toFile: filePath, atomically: true, encoding: .utf8)
            return .configFileCreatedSuccessfully(Constants.configFileName)
        } catch {
            return .failedToCreateConfigFile(Constants.configFileName, error.localizedDescription)
        }
    }

    public func check(
        _ directoryOrSwiftFilePath: String,
        withFix: Bool,
        isRunningFromCLI: Bool = true,
        onlyGitModified: Bool = false,
        completion: @escaping CompletionHandler) {
        self.withFix = withFix
        completionHandler = completion

        do {
            var swiftFiles: [URL] = []
            let pathType = getPathType(path: directoryOrSwiftFilePath)
            switch pathType {
            case .file:
                let swiftFilePath = directoryOrSwiftFilePath
                swiftFiles.append(.init(filePath: swiftFilePath))
            case .directory:
                let directoryPath = directoryOrSwiftFilePath
                if onlyGitModified {
                    swiftFiles = getModifiedSwiftFiles(in: directoryPath)
                } else {
                    swiftFiles = try fetchSwiftFiles(from: directoryPath)
                }
            case .notFound:
                break
            }
            let swiftFilesNumber = swiftFiles.count
            var swiftFilesCounter = 1

            let queue = DispatchQueue.global(qos: .userInitiated)
            let group = DispatchGroup()

            for file in swiftFiles {
                group.enter()
                queue.async {
                    defer { group.leave() }

                    do {
                        print("Checking '\(file.lastPathComponent)' (\(swiftFilesCounter)/\(swiftFilesNumber)")
                        try self.processFile(file)
                        swiftFilesCounter += 1
                    } catch {
                        print(Constants.getMessage(.genericError(error.localizedDescription)))
                    }
                }
            }
            group.notify(queue: .main) { [weak self] in
                self?.completionHandler?()
            }
            if isRunningFromCLI {
                dispatchMain()
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

    private enum PathType {
        case file
        case directory
        case notFound
    }

    private func getPathType(path: String) -> PathType {
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

    private func getModifiedSwiftFiles(in directory: String) -> [URL] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.currentDirectoryURL = URL(fileURLWithPath: directory)
        task.arguments = ["status", "--porcelain"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()

            guard let output = String(data: data, encoding: .utf8) else {
                print("Error: Unable to read git status output")
                return []
            }

            let directoryURL = URL(fileURLWithPath: directory)

            let modifiedFiles = output.components(separatedBy: .newlines)
                .compactMap { line -> URL? in
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedLine.isEmpty else {
                        return nil
                    }

                    let components = trimmedLine.split(
                        maxSplits: 1,
                        omittingEmptySubsequences: true) { $0.isWhitespace }
                    guard components.count == 2 else {
                        return nil
                    }

                    let status = String(components[0])
                    let filePath = String(components[1]).replace("\"", "")

                    guard filePath.hasSuffix(".swift") else {
                        return nil
                    }

                    switch status {
                    case "M", "A", "MM":
                        return URL(fileURLWithPath: filePath, relativeTo: directoryURL)
                    case "R":
                        let parts = filePath.components(separatedBy: " -> ")
                        if parts.count == 2, parts[1].hasSuffix(".swift") {
                            return URL(fileURLWithPath: parts[1], relativeTo: directoryURL)
                        }
                        return nil
                    default:
                        return nil
                    }
                }

            return modifiedFiles
        } catch {
            print("Error: \(error.localizedDescription)")
            return []
        }
    }

    private func shouldExclude(file: URL) -> Bool {
        guard let config = config else {
            return false
        }

        for pattern in config.ignoredPatternsOfFilesOrDirectories where file.path().matches(pattern) {
            return true
        }

        if config.excludedFiles.contains(where: { file.lastPathComponent == $0 }) {
            return true
        }

        return false
    }

    private func shouldExclude(directory: URL) -> Bool {
        guard let config = config else {
            return false
        }

        let directoryPath = directory.path

        if config.excludedDirectories.contains(where: { directoryPath.hasSuffix($0) }) {
            return true
        }

        for pattern in config.ignoredPatternsOfFilesOrDirectories {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: directoryPath.utf16.count)
                if regex.firstMatch(in: directoryPath, options: [], range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    private func processFile(_ url: URL) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        let sourceFile = Parser.parse(source: source)
        let visitor = CodeVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        if let config = config, config.rules.contains(.supportOneLineComment) {
            visitor.extractOneLineComments(from: url.path)
        }

        if let config = config, config.rules.contains(.supportMultiLineComment) {
            visitor.extractMultiLineComments(from: url.path)
        }

        for item in visitor.authorName {
            checker?.ignoredWords.insert(item)
        }

        let sourceLocationConverter = SourceLocationConverter(fileName: url.path, tree: sourceFile)
        checkSpelling(
            in: visitor,
            filePath: url.path,
            sourceLocationConverter: sourceLocationConverter)
    }

    private func renameInFile(misspelledWord: String, correctWord: String, filePath: String) -> Bool {
        do {
            var fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
            fileContents = fileContents.replace(misspelledWord, correctWord)
            try fileContents.write(toFile: filePath, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    private func checkSpelling(
        in visitor: CodeVisitor,
        filePath: String,
        sourceLocationConverter: SourceLocationConverter) {
        /* for (identifier, position, kind) in visitor.globalOrConstantVariables {
             if kind == Constants.letSwiftKeyword || kind == Constants.varSwiftKeyword {
                 processSpelling(
                     for: identifier,
                     position: position,
                     filePath: filePath,
                     sourceLocationConverter: sourceLocationConverter)
             }
         } */

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
            let enumName = node.name.text
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
            let className = node.name.text
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
            let functionName = node.name.text
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
            let attributeName = node.attributeName.description
            let startLocation = node.startLocation(converter: sourceLocationConverter)
            processSpelling(
                for: attributeName,
                startLocation: startLocation,
                filePath: filePath,
                sourceLocationConverter: sourceLocationConverter)
        }

        for node in visitor.customOperators {
            let operatorName = node.name.text
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
            for parameter in node.parameterClause.parameters {
                let paramName = parameter.firstName.text ?? parameter.secondName?.text ?? ""
                if !paramName.isEmpty {
                    let startLocation = parameter.startLocation(converter: sourceLocationConverter)
                    processSpelling(
                        for: paramName,
                        startLocation: startLocation,
                        filePath: filePath,
                        sourceLocationConverter: sourceLocationConverter)
                }

                let type = parameter.type
                let typeName = type.description.trimmingCharacters(in: .whitespaces)
                let startLocation = type.startLocation(converter: sourceLocationConverter)
                processSpelling(
                    for: typeName,
                    startLocation: startLocation,
                    filePath: filePath,
                    sourceLocationConverter: sourceLocationConverter)
            }

            let returnClause = node.returnClause
            let returnTypeName = returnClause.type.description.trimmingCharacters(
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

        if let config = config {
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
        let pattern = "^(https?|ftp)://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}(/[a-zA-Z0-9#?&=_-]*)?$"

        let urlString = urlString.remove(Constants.quoteCharacter)
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: urlString.utf16.count)

        if let match = regex?.firstMatch(in: urlString, options: [], range: range) {
            return match.range.location != NSNotFound
        }

        return false
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
            line = sourceLocation.line
            column = sourceLocation.column
        } else {
            line = startLocation?.line ?? 0
            column = getColumn(line: line, identifier: string, filePath: filePath)
        }

        var currentWordColumn = column

        var string = string.trimmingCharacters(in: .whitespaces)

        if let config = config {
            if config.rules.contains(.ignoreUrls), isValidURL(string) {
                return
            }
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
                        var element = element
                        element = element.replace(Constants.quoteCharacter, Constants.emptyString)
                        element = cleanString(element)
                        if element.isEmpty || isEnglishContraction(element) {
                            continue
                        }
                        currentWordColumn = getColumn(
                            line: line, identifier: element, filePath: filePath)
                        checkWord(word: element)
                        // currentWordColumn += word.count
                    }
                }
            }
        } else {
            let string = string.replace(Constants.quoteCharacter, Constants.emptyString)
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
            word = word.remove(Constants.possessiveApostrophe)
            word = word.remove(Constants.quoteCharacter)
            word = word.remove("\n")

            if word.isEmpty {
                return
            }

            guard
                let config = config,
                let checker = checker else {
                return
            }

            var isMisspelledWordCorrected = false
            let corrections = checker.checkAndSuggestCorrections(
                word: word, languages: config.languages)
            if !corrections.isEmpty {
                for (misspelledWord, suggestions) in corrections {
                    if !withFix, suggestions.isEmpty {
                        print(
                            Constants.getMessage(
                                .wordIsMisspelled(
                                    path: filePath,
                                    line: line,
                                    column: currentWordColumn,
                                    severity: Constants.Severity.warning.rawValue,
                                    word: misspelledWord)))
                        allMisspelledWords.append(misspelledWord)
                        misspelledWordsNumber += 1
                    } else {
                        let isIgnoreCapitalizationRuleEnabled = config.rules.contains(
                            .ignoreCapitalization)
                        let isSupportFlatCaseRuleEnabled = config.rules.contains(.supportFlatCase)

                        var shouldCapitalizeWord = false
                        var areWordsInFlatCaseFullyCorrect = false

                        if isSupportFlatCaseRuleEnabled {
                            for suggestion in suggestions where misspelledWord == joinWords(suggestion) {
                                areWordsInFlatCaseFullyCorrect = true
                                break
                            }
                        }

                        for suggestion in suggestions where misspelledWord == suggestion.lowercased() {
                            shouldCapitalizeWord = true
                            break
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
                                            severity: Constants.Severity.warning.rawValue,
                                            word: misspelledWord,
                                            suggestions: suggestions)))
                                allMisspelledWords.append(misspelledWord)
                                misspelledWordsNumber += 1
                            } else {
                                correctedWordsNumber += 1
                            }
                        }
                    }
                }
            }
        }
    }

    private func isValidSwiftCode(_ code: String) -> Bool {
        let sourceFile = Parser.parse(source: code)
        let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: sourceFile)
        return diagnostics.isEmpty
    }

    private func isEnglishContraction(_ word: String) -> Bool {
        guard word.contains("'") else {
            return false
        }

        let lowercasedWord = word.lowercased()

        if Constants.specificContractions.contains(lowercasedWord) {
            return true
        }

        for pronoun in Constants.validPronouns {
            for contraction in Constants.pronounContractions where lowercasedWord == pronoun + contraction {
                return true
            }
        }

        for verb in Constants.validVerbs {
            let contractionForm = verb.hasSuffix("n") ? verb + "t" : verb + Constants.negativeContraction
            if lowercasedWord == contractionForm {
                return true
            }
        }

        return false
    }

    private func getColumn(line: Int, identifier: String, filePath: String) -> Int {
        do {
            let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = fileContent.components(separatedBy: .newlines)
            let lineContent = lines[line - 1]
            let index =
                lineContent.range(of: identifier)?.lowerBound.utf16Offset(in: lineContent) ?? 0
            return index + 1
        } catch {
            print(Constants.getMessage(.failedToReadFile(error.localizedDescription)))
        }
        return 1
    }
}
