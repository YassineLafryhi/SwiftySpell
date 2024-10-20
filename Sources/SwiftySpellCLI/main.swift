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
        swiftySpell.setConfig(configFilePath: projectConfigFilePath)
    } else if fileManager.fileExists(atPath: globalConfigFilePath) {
            swiftySpell.setConfig(configFilePath: globalConfigFilePath)
    } else {
        Utilities.printWarning(Utilities.getMessage(.configFileNotFound(Constants.configFileName)))
    }
}

internal let updateCommand = command {
    guard let url = URL(string: Constants.releasesURL) else {
        print("Error: Invalid GitHub API URL")
        return
    }
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            print("Error: No data received")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let tagName = json["tag_name"] as? String,
               let assets = json["assets"] as? [[String: Any]],
               let asset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
               let downloadUrl = asset["browser_download_url"] as? String {
                
                print("Latest version: \(tagName)")
                if tagName != Constants.currentVersion {
                    downloadAndUnzip(url: downloadUrl)
                } else {
                    print("Already up to date")
                }
                
            } else {
                print("Error: Unable to parse GitHub API response")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    task.resume()
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))
}

func downloadAndUnzip(url: String) {
   // TODO: Implement this
}

internal enum CLICommand: String {
    case version
    case languages
    case `init`
    case rules
    case check
    case fix
    case update
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
    // $0.addCommand(CLICommand.update.rawValue, "Check for updates, download, and install the latest version.", updateCommand)

}

main.run()
