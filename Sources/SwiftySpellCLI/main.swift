//
//  main.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 19/2/2024.
//

import Commander
import Foundation
import SwiftySpellCore

internal var swiftySpell = SwiftySpell()

internal let initCommand = command {
    let currentPath = FileManager.default.currentDirectoryPath
    let result = swiftySpell.createConfigFile(at: currentPath)
    Utilities.print(Utilities.getMessage(result), color: .red, style: .bold)
}

internal let checkCommand = command(
    Argument<String>("path", description: "The project path .")) { path in
    let startAsync = CFAbsoluteTimeGetCurrent()
    loadConfig(path)
    swiftySpell.check(path, withFix: false) {
        let endAsync = CFAbsoluteTimeGetCurrent()
        let elapsedTime = Int(endAsync - startAsync)
        print(Utilities.getMessage(.doneChecking(swiftySpell.misspelledWordsNumber, elapsedTime)))
        exit(0)
    }
}

internal let fixCommand = command(
    Argument<String>("path", description: "The project (or Swift file) path .")) { path in
    let startAsync = CFAbsoluteTimeGetCurrent()
    loadConfig(path)
    swiftySpell.check(path, withFix: true) {
        let endAsync = CFAbsoluteTimeGetCurrent()
        let elapsedTime = Int(endAsync - startAsync)
        print(Utilities.getMessage(.doneCheckingAndCorrecting(
            swiftySpell.misspelledWordsNumber,
            swiftySpell.correctedWordsNumber,
            elapsedTime)))
        exit(0)
    }
}

internal let languagesCommand = command {
    let supportedLanguages = swiftySpell.getSupportedLanguages()
    Utilities.print("Supported languages:", color: .green, style: .bold)
    for language in supportedLanguages {
        Utilities.print("  - \(language)", color: .blue, style: .bold)
    }
}

internal let rulesCommand = command {
    Utilities.print("Supported rules:", color: .green, style: .bold)
    for rule in swiftySpell.getSupportedRules() {
        Utilities.print("  - \(rule)", color: .blue, style: .bold)
    }
}

internal let versionCommand = command {
    let version = swiftySpell.getCurrentVersion()
    Utilities.print("\(Constants.name) v\(version)", color: .green, style: .bold)
}

private func loadConfig(_ directoryOrSwiftFilePath: String) {
    let fileManager = FileManager.default
    var projectPath: String

    let pathType = Utilities.getPathType(path: directoryOrSwiftFilePath)

    switch pathType {
    case .file:
        projectPath = URL(fileURLWithPath: directoryOrSwiftFilePath).deletingLastPathComponent().path
    case .directory:
        projectPath = directoryOrSwiftFilePath
    case .notFound:
        Utilities.printError(Utilities.getMessage(.projectOrSwiftFilePathDoesNotExist))
        exit(1)
    }

    let homeDirectory = fileManager.homeDirectoryForCurrentUser
    let projectConfigFilePath = "\(projectPath)/\(Constants.configFileName)"
    let globalConfigFilePath = homeDirectory.appendingPathComponent(Constants.configFileName).path

    if fileManager.fileExists(atPath: projectConfigFilePath) {
        swiftySpell = SwiftySpell(configFilePath: projectConfigFilePath)
    } else if fileManager.fileExists(atPath: globalConfigFilePath) {
        swiftySpell = SwiftySpell(configFilePath: globalConfigFilePath)
    } else {
        Utilities.printWarning(Utilities.getMessage(.configFileNotFound(Constants.configFileName)))
    }
}

internal enum CLICommand: String {
    case version
    case languages
    case `init`
    case rules
    case check
    case fix
}

internal let main = Group {
    $0.addCommand(CLICommand.version.rawValue, "Print the current version of \(Constants.name).", versionCommand)
    $0.addCommand(CLICommand.languages.rawValue, "List supported languages.", languagesCommand)
    $0.addCommand(
        CLICommand.`init`.rawValue,
        "Initialize a new \(Constants.configFileName) file with sample configuration.",
        initCommand)
    $0.addCommand(CLICommand.rules.rawValue, "List supported rules.", rulesCommand)
    $0.addCommand(CLICommand.check.rawValue, "Start \(Constants.name).", checkCommand)
    $0.addCommand(CLICommand.fix.rawValue, "Correct most spelling errors.", fixCommand)
}

main.run()
