//
//  main.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 19/2/2024.
//

import ArgumentParser
import Foundation
import SwiftySpellCore

internal var swiftySpell = SwiftySpell()

internal struct Initialize: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new \(Constants.configFileName) file with sample configuration.")

    func run() throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let result = swiftySpell.createConfigFile(at: currentPath)
        Utilities.print(Utilities.getMessage(result), color: .red, style: .bold)
    }
}

internal struct Check: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Start \(Constants.name).")

    @Argument(help: "The project path.")
    var path: String

    func run() throws {
        let startAsync = CFAbsoluteTimeGetCurrent()
        loadConfig(path)
        swiftySpell.check(path, withFix: false) {
            let endAsync = CFAbsoluteTimeGetCurrent()
            let elapsedTime = Int(endAsync - startAsync)
            print(Utilities.getMessage(.doneChecking(swiftySpell.misspelledWordsNumber, elapsedTime)))
            Foundation.exit(0)
        }
    }
}

internal struct Fix: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "fix",
        abstract: "Correct most spelling errors.")

    @Argument(help: "The project (or Swift file) path")
    var path: String

    func run() throws {
        let startAsync = CFAbsoluteTimeGetCurrent()
        loadConfig(path)
        swiftySpell.check(path, withFix: true) {
            let endAsync = CFAbsoluteTimeGetCurrent()
            let elapsedTime = Int(endAsync - startAsync)
            print(Utilities.getMessage(.doneCheckingAndCorrecting(
                swiftySpell.misspelledWordsNumber,
                swiftySpell.correctedWordsNumber,
                elapsedTime)))
            Foundation.exit(0)
        }
    }
}

internal struct Languages: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "List supported languages.")

    func run() throws {
        let supportedLanguages = swiftySpell.getSupportedLanguages()
        Utilities.print("Supported languages:", color: .green, style: .bold)
        for language in supportedLanguages {
            Utilities.print("  - \(language)", color: .blue, style: .bold)
        }
    }
}

internal struct Rules: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "rules",
        abstract: "List supported rules.")

    func run() throws {
        Utilities.print("Supported rules:", color: .green, style: .bold)
        for rule in swiftySpell.getSupportedRules() {
            Utilities.print("  - \(rule)", color: .blue, style: .bold)
        }
    }
}

internal struct Version: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print the current version of \(Constants.name).")

    func run() throws {
        let version = swiftySpell.getCurrentVersion()
        Utilities.print("\(Constants.name) v\(version)", color: .green, style: .bold)
    }
}

internal struct Update: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Check for updates, download, and install the latest version.")

    func run() throws {
        guard let url = URL(string: Constants.latestReleaseURL) else {
            print("Error: Invalid GitHub API URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("Error: No data received")
                return
            }

            do {
                if
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let tagName = json["tag_name"] as? String,
                    let assets = json["assets"] as? [[String: Any]],
                    let asset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
                    let downloadUrl = asset["browser_download_url"] as? String {
                    print("Latest version: \(tagName)")
                    if tagName != Constants.currentVersion {
                        // downloadAndUnzip(url: downloadUrl)
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
        swiftySpell.setConfig()
        Utilities.printWarning(Utilities.getMessage(.configFileNotFound(Constants.configFileName)))
    }
}

@main
internal struct Main: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "swiftyspell",
        abstract: "A tool for checking spelling in Swift code",
        subcommands: [
            Initialize.self,
            Version.self,
            Languages.self,
            Rules.self,
            Check.self,
            Fix.self
            // Update.self
        ],
        defaultSubcommand: Check.self)
}
