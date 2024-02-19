import AppKit
import Foundation
import SwiftSyntax
import SwiftSyntaxParser
import Yams

class SwiftySpellCodeVisitor: SyntaxVisitor {
    var variables: [(String, AbsolutePosition)] = []
    var globalOrConstantVariables: [(identifier: String, position: AbsolutePosition, kind: String)] = []
    var classes: [(String, AbsolutePosition)] = []
    var structs: [(String, AbsolutePosition)] = []
    var functions: [(String, AbsolutePosition)] = []
    var strings: [(String, AbsolutePosition)] = []
    var enums: [(String, AbsolutePosition)] = []
    var typeAliases: [(String, AbsolutePosition)] = []
    var protocols: [(String, AbsolutePosition)] = []
    var extensions: [(String, AbsolutePosition)] = []
    var functionParameters: [(String, AbsolutePosition)] = []

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let protocolName = node.identifier.text
        let position = node.position
        protocols.append((protocolName, position))
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let extendedTypeName = node.extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let position = node.position
        extensions.append((extendedTypeName, position))
        return .visitChildren
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.identifier.text
        let position = node.position
        typeAliases.append((typeName, position))
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let enumName = node.identifier.text
        let position = node.position
        enums.append((enumName, position))
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            switch binding.pattern {
            case let identifierPattern:
                let position = identifierPattern.position
                variables.append((identifierPattern.description, position))
            }
        }

        let isGlobalOrConstant = !node.isContainedInFunctionBody

        if isGlobalOrConstant {
            for binding in node.bindings {
                if let identifier = binding.pattern.firstToken?.text {
                    let position = binding.position
                    let kind = node.letOrVarKeyword.text
                    globalOrConstantVariables.append((identifier, position, kind))
                }
            }
        }

        return .visitChildren
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let stringLiteral = node.description.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let position = node.position
        strings.append((stringLiteral, position))
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.identifier.text
        let position = node.position
        classes.append((className, position))
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let structName = node.identifier.text
        let position = node.position
        structs.append((structName, position))
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.identifier.text
        if isCFunction(name: functionName) {
            return .skipChildren
        }

        let position = node.position
        functions.append((functionName, position))

        for parameter in node.signature.input.parameterList {
            let paramName = parameter.firstName?.text ?? ""
            let position = parameter.position
            functionParameters.append((paramName, position))
        }

        return .visitChildren
    }

    private func isCFunction(name: String) -> Bool {
        return name.hasPrefix("c_") || name.hasPrefix("C_")
    }
}

class SwiftySpellChecker {
    var ignoreList: Set<String> = []
    var excludePatterns: [NSRegularExpression] = []

    init(ignoreList: Set<String>, excludePatterns: [String]) {
        self.ignoreList = ignoreList
        self.excludePatterns = excludePatterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [])
        }
    }

    func shouldExclude(word: String) -> Bool {
        for pattern in excludePatterns {
            let range = NSRange(location: 0, length: word.utf16.count)
            if pattern.firstMatch(in: word, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    func checkAndSuggestCorrections(text: String) -> [String: [String]] {
        let checker = NSSpellChecker.shared
        var corrections: [String: [String]] = [:]
        var searchRange = NSRange(location: 0, length: text.utf16.count)

        while searchRange.location < text.utf16.count {
            let result = checker.checkSpelling(of: text, startingAt: searchRange.location, language: "en", wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)

            if result.length == 0 { break }

            let misspelledWordRange = NSRange(location: result.location, length: result.length)
            let misspelledWord = (text as NSString).substring(with: misspelledWordRange)

            // TODO: Complete work here
            // let firstcapitalizedWord = misspelledWord.prefix(1).capitalized + misspelledWord.dropFirst().lowercased()

            if ignoreList.contains(misspelledWord) || shouldExclude(word: misspelledWord) {
                searchRange.location = misspelledWordRange.location + misspelledWordRange.length
                searchRange.length = text.utf16.count - searchRange.location
                continue
            }

            if let suggestions = checker.guesses(forWordRange: misspelledWordRange, in: text, language: "en", inSpellDocumentWithTag: 0), !suggestions.isEmpty {
                corrections[misspelledWord] = suggestions
            }
            var correctionsForCurrentWord = corrections[misspelledWord] ?? []
            correctionsForCurrentWord.append("_")
            corrections[misspelledWord] = correctionsForCurrentWord

            searchRange.location = misspelledWordRange.location + misspelledWordRange.length
            searchRange.length = text.utf16.count - searchRange.location
        }
        return corrections
    }
}

class SwiftySpellConfiguration {
    var ignoreList: Set<String> = []
    var excludePatterns: [String] = []
    var excludeFiles: [String] = []
    var excludeDirectories: [String] = []

    init(configFilePath: String) {
        loadConfiguration(from: configFilePath)
    }

    private func loadConfiguration(from filePath: String) {
        do {
            let fileContents = try String(contentsOfFile: filePath)
            if let yaml = try? Yams.load(yaml: fileContents) as? [String: [String]] {
                ignoreList = Set(yaml["ignoreList"] ?? [])
                excludePatterns = yaml["excludePatterns"] ?? []
                excludeFiles = yaml["excludeFiles"] ?? []
                excludeDirectories = yaml["excludeDirectories"] ?? []
            }
        } catch {
            print("error: Error loading configuration: \(error.localizedDescription)")
        }
    }
}

class SwiftySpellCLI {
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

        let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles, .skipsPackageDescendants])

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
        return config.excludeDirectories.contains(where: { directory.path.contains("\($0)") })
    }

    private func processFile(_ url: URL) throws {
        let sourceFile = try SyntaxParser.parse(url)
        let visitor = SwiftySpellCodeVisitor(viewMode: .all)
        visitor.walk(sourceFile)

        let sourceLocationConverter = SourceLocationConverter(file: url.path, tree: sourceFile)
        checkSpelling(in: visitor, filePath: url.path, sourceLocationConverter: sourceLocationConverter)
    }

    private func checkSpelling(in visitor: SwiftySpellCodeVisitor, filePath: String, sourceLocationConverter: SourceLocationConverter) {
        for (identifier, position, kind) in visitor.globalOrConstantVariables {
            if kind == "let" || kind == "var" {
                processSpelling(for: identifier, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
            }
        }

        for (variable, position) in visitor.variables {
            processSpelling(for: variable, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }

        for (paramName, position) in visitor.functionParameters {
            processSpelling(for: paramName, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }

        for (extendedTypeName, position) in visitor.extensions {
            processSpelling(for: extendedTypeName, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (protocolName, position) in visitor.protocols {
            processSpelling(for: protocolName, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (typeName, position) in visitor.typeAliases {
            processSpelling(for: typeName, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (enumName, position) in visitor.enums {
            processSpelling(for: enumName, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (string, position) in visitor.strings {
            processSpelling(for: string, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (aClass, position) in visitor.classes {
            processSpelling(for: aClass, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (aStruct, position) in visitor.structs {
            processSpelling(for: aStruct, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
        for (function, position) in visitor.functions {
            processSpelling(for: function, position: position, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
        }
    }

    func getFileName(from filePath: String) -> String {
        let fileURL = URL(fileURLWithPath: filePath)
        return fileURL.lastPathComponent
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

    private func processSpelling(for word: String, position: AbsolutePosition, filePath: String, sourceLocationConverter: SourceLocationConverter) {
        let sourceLocation = sourceLocationConverter.location(for: position)
        let line = sourceLocation.line ?? 0
        let column = sourceLocation.column ?? 0

        let allWords = splitCamelCaseString(word)

        for aWord in allWords {
            let corrections = checker.checkAndSuggestCorrections(text: aWord)
            if corrections.count > 0 {
                for (misspelledWord, suggestions) in corrections {
                    // TODO: Remove "_" from suggestions array
                    // print("\(filePath):\(line):\(column): warning: '\(misspelledWord)' may be misspelled, Suggestions: \(suggestions)")
                    print("\(filePath):\(line):\(column): warning: '\(misspelledWord)' may be misspelled !")
                }
            }
        }
    }
}

extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

extension SyntaxProtocol {
    var isContainedInFunctionBody: Bool {
        var current: SyntaxProtocol? = self
        while let currentNode = current {
            if currentNode.as(Syntax.self)?.asProtocol(SyntaxProtocol.self) is FunctionDeclSyntax {
                return true
            }
            current = currentNode.parent
        }
        return false
    }
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("error: SwiftySpell: Missing project path argument.")
    exit(1)
}

let projectPath = arguments[1]

let fileManager = FileManager.default
let configFilePath = "\(projectPath)/.swiftyspell.yml"

if !fileManager.fileExists(atPath: configFilePath) {
    print("warning: SwiftySpell: Configuration file \(".swiftyspell.yml") not found in the project path.")
}

let swiftySpellCLI = SwiftySpellCLI(configFilePath: configFilePath)
swiftySpellCLI.run(for: projectPath)
