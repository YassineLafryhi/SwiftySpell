//
//  Configuration.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import Yams

public class Configuration {
    var languages: Set<String> = []
    var exclude: Set<String> = []
    var rules: Set<SupportedRule> = []
    var ignore: Set<String> = []

    var ignoredPatternsOfWords: [String] = []
    var ignoredPatternsOfFilesOrDirectories: [String] = []

    var excludedFiles: [String] = []
    var excludedDirectories: [String] = []

    private var rawIgnoreList: [String] = []
    private var rulesSet: Set<String> = []
    private var duplicates = Set<String>()
    private var capitalizedPairs = [(String, String)]()

    init() {
        languages = [Constants.defaultLanguage]
        for directory in Constants.defaultExcludedDirectories {
            exclude.insert(directory)
        }
        for file in Constants.defaultExcludedFiles {
            exclude.insert(file)
        }
        for rule in Configuration.SupportedRule.allCases {
            rulesSet.insert(rule.rawValue)
        }

        let result = prepareConfiguration()
        print(Constants.getMessage(result))
    }

    init(configFilePath: String) {
        do {
            let fileContents = try String(contentsOfFile: configFilePath, encoding: .utf8)
            if let yaml = try? Yams.load(yaml: fileContents) as? [String: [String]] {
                languages = Set(yaml["languages"] ?? [Constants.defaultLanguage])
                rawIgnoreList = yaml["ignore"] ?? []
                exclude = Set(yaml["exclude"] ?? [])
                rulesSet = Set(yaml["rules"] ?? [])
            }

            let result = prepareConfiguration()
            print(Constants.getMessage(result))
        } catch {
            print(Constants.getMessage(.configLoadingError(error.localizedDescription)))
        }
    }

    private func prepareConfiguration() -> Constants.MessageType {
        for element in rulesSet {
            if let rule = SupportedRule(rawValue: element) {
                rules.insert(rule)
            } else {
                return .unknownRule(element)
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

        if rules.contains(.supportBritishWords) {
            languages.insert(Constants.languageCodeOfBritishEnglish)
        }

        if rules.contains(.ignoreSwiftKeywords) {
            for keyword in Constants.swiftKeywords {
                ignore.insert(keyword)
                ignore.insert(keyword.capitalized)
            }
        }

        if rules.contains(.ignoreShortenedWords) {
            for word in Constants.shortenedWords {
                ignore.insert(word)
                ignore.insert(word.capitalized)
            }
        }

        if rules.contains(.ignoreCommonlyUsedWords) {
            for word in Constants.commonlyUsedWords {
                ignore.insert(word)
                ignore.insert(word.capitalized)
            }

            for pattern in Constants.otherWordPatterns {
                ignoredPatternsOfWords.append(pattern)
            }
        }

        if rules.contains(.ignoreLoremIpsum) {
            for word in Constants.loremIpsumWords {
                ignore.insert(word)
                ignore.insert(word.capitalized)
            }
        }

        if rules.contains(.ignoreHtmlTags) {
            for word in Constants.htmlTags {
                ignore.insert(word)
                ignore.insert(word.capitalized)
            }
        }

        if !duplicates.isEmpty {
            return .duplicatesInIgnoreList(duplicates)
        }

        if !capitalizedPairs.isEmpty {
            return .capitalizedPairsInIgnoreList(capitalizedPairs)
        }

        return .success
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
        case supportBritishWords = "support_british_words"
        case ignoreSwiftKeywords = "ignore_swift_keywords"
        case ignoreShortenedWords = "ignore_shortened_words"
        case ignoreCommonlyUsedWords = "ignore_commonly_used_words"
        case ignoreLoremIpsum = "ignore_lorem_ipsum"
        case ignoreHtmlTags = "ignore_html_tags"
        case ignoreUrls = "ignore_urls"
    }
}
