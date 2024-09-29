//
//  main.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 19/2/2024.
//

import AppKit
import Commander
import Foundation
import Yams

internal var swiftySpellCLI = SwiftySpellCLI()

internal let initCommand = command {
    let currentPath = FileManager.default.currentDirectoryPath
    let filePath = "\(currentPath)/\(Constants.configFileName)"

    do {
        try Constants.sampleConfig.write(toFile: filePath, atomically: true, encoding: .utf8)
        Utilities.printInColors(
            Constants.getMessage(.configFileCreatedSuccessfully(Constants.configFileName)),
            color: .green,
            style: .bold)
    } catch {
        Utilities.printInColors(
            Constants.getMessage(.failedToCreateConfigFile(Constants.configFileName, error.localizedDescription)),
            color: .red,
            style: .bold)
    }
}

internal let checkCommand = command(
    Argument<String>("path", description: "The project path .")) { path in

    loadConfig(projectPath: path)
    swiftySpellCLI.check(path, withFix: false)
}

internal let fixCommand = command(
    Argument<String>("path", description: "The project path .")) { path in

    loadConfig(projectPath: path)
    swiftySpellCLI.check(path, withFix: true)
}

internal let languagesCommand = command {
    let supportedLanguages = NSSpellChecker.shared.availableLanguages

    Utilities.printInColors("Supported languages:", color: .green, style: .bold)
    for language in supportedLanguages {
        Utilities.printInColors("  - \(language)", color: .blue, style: .bold)
    }
}

internal let rulesCommand = command {
    Utilities.printInColors("Supported rules:", color: .green, style: .bold)
    for rule in SwiftySpellConfiguration.SupportedRule.allCases {
        Utilities.printInColors("  - \(rule)", color: .blue, style: .bold)
    }
}

internal let versionCommand = command {
    let version = Constants.currentVersion
    Utilities.printInColors("\(Constants.name) v\(version)", color: .green, style: .bold)
}

private func loadConfig(projectPath: String) {
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: projectPath, isDirectory: nil) {
        Utilities.printError(Constants.getMessage(.projectPathDoesNotExist))
        exit(1)
    }

    let homeDirectory = fileManager.homeDirectoryForCurrentUser
    let projectConfigFilePath = "\(projectPath)/\(Constants.configFileName)"
    let globalConfigFilePath = homeDirectory.appendingPathComponent(Constants.configFileName).path

    if fileManager.fileExists(atPath: projectConfigFilePath) {
        swiftySpellCLI = SwiftySpellCLI(configFilePath: projectConfigFilePath)
    } else if fileManager.fileExists(atPath: globalConfigFilePath) {
        swiftySpellCLI = SwiftySpellCLI(configFilePath: globalConfigFilePath)
    } else {
        Utilities.printWarning(Constants.getMessage(.configFileNotFound(Constants.configFileName)))
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
