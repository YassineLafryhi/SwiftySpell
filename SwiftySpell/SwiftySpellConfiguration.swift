//
//  SwiftySpellConfiguration.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Yams

internal class SwiftySpellConfiguration: Codable {
    var languages: [String] = []
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
            var duplicates = Set<String>()
            var capitalizedPairs = [(String, String)]()
            if let yaml = try? Yams.load(yaml: fileContents) as? [String: [String]] {
                languages = yaml["languages"] ?? ["en"]
                let rawIgnoreList = yaml["ignoreList"] ?? []
                excludePatterns = yaml["excludePatterns"] ?? []
                excludeFiles = yaml["excludeFiles"] ?? []
                excludeDirectories = yaml["excludeDirectories"] ?? []

                for word in rawIgnoreList where !ignoreList.insert(word).inserted {
                    duplicates.insert(word)
                }

                for word in rawIgnoreList {
                    let capitalizedWord = word.capitalized

                    if ignoreList.contains(capitalizedWord), word != capitalizedWord {
                        capitalizedPairs.append((word, capitalizedWord))
                    }
                }

                for word in rawIgnoreList {
                    let capitalizedWord = word.capitalized
                    ignoreList.insert(capitalizedWord)
                }
            }

            if !duplicates.isEmpty {
                Utilities.printWarning(
                    "The following words are duplicated in the ignore list and can be removed: \(duplicates.joined(separator: ", "))")
            }

            if !capitalizedPairs.isEmpty {
                Utilities.printWarning(
                    "The following word pairs exist in both lowercase and capitalized forms: " + capitalizedPairs
                        .map { "\($0.0) and \($0.1)" }
                        .joined(separator: ", ") + ". The lowercase version is sufficient for SwiftySpell.")
            }

        } catch {
            Utilities.printError("Error loading configuration: \(error.localizedDescription)")
        }
    }
}
