//
//  SwiftySpellConfiguration.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import Yams

internal class SwiftySpellConfiguration: Codable {
    var languages: Set<String> = []
    var exclude: Set<String> = []
    var rules: Set<SupportedRule> = []
    var ignore: Set<String> = []

    var ignoredPatternsOfWords: [String] = []
    var ignoredPatternsOfFilesOrDirectories: [String] = []

    var excludedFiles: [String] = []
    var excludedDirectories: [String] = []

    init(configFilePath: String) {
        loadConfiguration(from: configFilePath)
    }

    private func loadConfiguration(from filePath: String) {
        do {
            let fileContents = try String(contentsOfFile: filePath)
            var duplicates = Set<String>()
            var capitalizedPairs = [(String, String)]()
            if let yaml = try? Yams.load(yaml: fileContents) as? [String: [String]] {
                languages = Set(yaml["languages"] ?? ["en"])
                let rawIgnoreList = yaml["ignore"] ?? []
                exclude = Set(yaml["exclude"] ?? [])
                let rulesSet = Set(yaml["rules"] ?? [])

                for element in rulesSet {
                    if let rule = SupportedRule(rawValue: element) {
                        rules.insert(rule)
                    } else {
                        Utilities.printWarning(Constants.getMessage(.unknownRule(element)))
                    }
                }

                var ignoredWords: [String] = []

                for element in rawIgnoreList {
                    if isValidRegex(element) {
                        ignoredPatternsOfWords.append(element)
                    } else {
                        ignoredWords.append(element)
                    }
                }

                for word in ignoredWords where !ignore.insert(word).inserted {
                    duplicates.insert(word)
                }

                for word in ignoredWords {
                    let capitalizedWord = word.capitalized

                    if ignore.contains(capitalizedWord), word != capitalizedWord {
                        capitalizedPairs.append((word, capitalizedWord))
                    }
                }

                for word in ignoredWords {
                    let capitalizedWord = word.capitalized
                    ignore.insert(capitalizedWord)
                }

                for element in exclude {
                    if isValidRegex(element) {
                        ignoredPatternsOfFilesOrDirectories.append(element)
                    } else {
                        if isFilePath(element) {
                            excludedFiles.append(element)
                        } else {
                            excludedDirectories.append(element)
                        }
                    }
                }

                if rules.contains(.ignoreSwiftKeywords) {
                    for keyword in Constants.swiftKeywords {
                        ignore.insert(keyword)
                    }
                }
            }

            if !duplicates.isEmpty {
                Utilities.printWarning(
                    Constants.getMessage(.duplicatesInIgnoreList(duplicates)))
            }

            if !capitalizedPairs.isEmpty {
                Utilities.printWarning(
                    Constants.getMessage(.capitalizedPairsInIgnoreList(capitalizedPairs)))
            }

        } catch {
            Utilities.printError(
                Constants.getMessage(.configLoadingError(error.localizedDescription)))
        }
    }

    private func isValidRegex(_ pattern: String) -> Bool {
        if pattern.range(of: Constants.regexSymbols, options: .regularExpression) == nil {
            return false
        }

        do {
            _ = try NSRegularExpression(pattern: pattern)
            return true
        } catch {
            return false
        }
    }

    private func isFilePath(_ path: String) -> Bool {
        path.hasSuffix(Constants.swiftFileExtension)
    }

    enum SupportedRule: String, Codable, CaseIterable {
        case ignoreCapitalization = "ignore_capitalization"
        case supportFlatCase = "support_flat_case"
        case supportOneLineComment = "support_one_line_comment"
        case supportMultiLineComment = "support_multi_line_comment"
        case ignoreSwiftKeywords = "ignore_swift_keywords"

        // TODO: Add support for these rules
        // case pluralConsistency = "plural_consistency"
        // case homophoneCheck = "homophone_check"
        // case possessiveApostrophe = "possessive_apostrophe"
    }
}
