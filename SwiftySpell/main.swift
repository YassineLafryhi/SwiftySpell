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

internal let initCommand = command {
    let sampleConfig = """
        # Languages to check
        languages:
          - en

        # Regular expressions to exclude
        excludePatterns:
          - \\b[0-9a-fA-F]{6}\\b
          - \\bhttps?:\\/\\/[^\\s]+\\b

        # Files to exclude
        excludeFiles:
          - Constants.swift

        # Directories to exclude
        excludeDirectories:
          - Pods

        # Words to ignore
        ignoreList:
          - iOS
        """

    let currentPath = FileManager.default.currentDirectoryPath
    let filePath = "\(currentPath)/\(Constants.configFileName)"

    do {
        try sampleConfig.write(toFile: filePath, atomically: true, encoding: .utf8)
        Utilities.printInColors("\(Constants.configFileName) file has been created successfully.", color: .green, style: .bold)
    } catch {
        Utilities.printInColors("Error creating \(Constants.configFileName) file: \(error)", color: .red, style: .bold)
    }
}

internal let checkCommand = command(
    Argument<String>("path", description: "The project path .")) { path in
    let fileManager = FileManager.default
    let homeDirectory = fileManager.homeDirectoryForCurrentUser
    let projectConfigFilePath = "\(path)/\(Constants.configFileName)"
    let globalConfigFilePath = homeDirectory.appendingPathComponent(Constants.configFileName).path

    let swiftySpellCLI: SwiftySpellCLI
    if fileManager.fileExists(atPath: projectConfigFilePath) {
        swiftySpellCLI = SwiftySpellCLI(configFilePath: projectConfigFilePath)
    } else if fileManager.fileExists(atPath: globalConfigFilePath) {
        swiftySpellCLI = SwiftySpellCLI(configFilePath: globalConfigFilePath)
    } else {
        Utilities.printError(
            "SwiftySpell: Configuration file \(Constants.configFileName) not found in the project path nor in the home directory.")
        exit(1)
    }

    swiftySpellCLI.run(for: path)
}

internal let languagesCommand = command {
    let supportedLanguages = NSSpellChecker.shared.availableLanguages

    Utilities.printInColors("Supported languages:", color: .green, style: .bold)
    for language in supportedLanguages {
        Utilities.printInColors("  - \(language)", color: .blue, style: .bold)
    }
}

internal let versionCommand = command {
    let version = Constants.currentVersion
    Utilities.printInColors("SwiftySpell v\(version)", color: .green, style: .bold)
}

internal let main = Group {
    $0.addCommand("version", "Print the current version of SwiftySpell.", versionCommand)
    $0.addCommand("languages", "List supported languages.", languagesCommand)
    $0.addCommand("init", "Initialize a new \(Constants.configFileName) file with sample configuration.", initCommand)
    $0.addCommand("check", "Start SwiftySpell.", checkCommand)
}

main.run()
