//
//  Constants.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation

public class Constants {
    public static let name = "SwiftySpell"
    public static let currentVersion = "0.9.7"
    public static let configFileName = ".swiftyspell.yml"
    public static let releasesURL = "https://api.github.com/repos/YassineLafryhi/SwiftySpell/releases/latest"

    static let defaultLanguage = "en"
    static let languageCodeOfBritishEnglish = "en_GB"
    static let defaultExcludedDirectories = ["Pods"]
    static let defaultExcludedFiles = ["Package.swift", "R.generated.swift"]

    static let createdBy = "Created by"
    static let copyright = "Copyright"
    static let on = "on"

    static let sampleConfig = """
        # Languages to check
        languages:
          - en
          #- en_GB

        # Directories/Files/Regular expressions to exclude
        exclude:
          - Pods
          - Constants.swift

        # Rules to apply
        rules:
          - support_flat_case
          - support_one_line_comment
          - support_multi_line_comment
          #- support_british_words
          #- ignore_capitalization
          - ignore_swift_keywords
          - ignore_commonly_used_words
          #- ignore_shortened_words
          #- ignore_lorem_ipsum
          #- ignore_html_tags
          - ignore_urls

        # Words/Regular expressions to ignore
        ignore:
          - iOS
        """

    static let delimiters = ",.:-;_!`@"
    static let blockCommentStart = "/*"
    static let blockCommentEnd = "*/"
    static let singleLineCommentStart = "//"
    static let quoteCharacter = "\""
    static let spaceCharacter = " "
    static let emptyString = ""
    static let newLineCharacter = "\\n"
    static let tabCharacter = "\\t"
    static let possessiveApostrophe = "'"
    static let possessiveMarker = "s"
    static let swiftFileExtension = "swift"
    static let hunspellAffixFileExtension = "aff"
    static let regexSymbols = "[.^$*+?()\\[\\]{}|\\\\]"
    static let letSwiftKeyword = "let"
    static let varSwiftKeyword = "var"

    public enum MessageType {
        case projectOrSwiftFilePathDoesNotExist
        case genericError(_ error: String)
        case configFileCreatedSuccessfully(_ fileName: String)
        case failedToCreateConfigFile(_ fileName: String, _ error: String)
        case configFileNotFound(_ fileName: String)
        case failedToReadFile(_ error: String)
        case wordIsMisspelled(path: String, line: Int, column: Int, severity: String, word: String)
        case wordIsMisspelledWithSuggestions(
            path: String,
            line: Int,
            column: Int,
            severity: String,
            word: String,
            suggestions: [String])
        case duplicatesInIgnoreList(_ duplicates: Set<String>)
        case capitalizedPairsInIgnoreList(_ pairs: [(String, String)])
        case configLoadingError(_ error: String)
        case unknownRule(_ rule: String)
        case doneChecking(_ misspelledWordsNumber: Int, _ elapsedTime: Int)
        case doneCheckingAndCorrecting(_ misspelledWordsNumber: Int, _ correctedWordsNumber: Int, _ elapsedTime: Int)
        case success
    }

    enum Severity: String {
        case error
        case warning
    }

    static func getMessage(_ message: Constants.MessageType) -> String {
        switch message {
        case .projectOrSwiftFilePathDoesNotExist:
            return "The given path does not exist."
        case let .configFileCreatedSuccessfully(fileName):
            return "\(fileName) config file has been created successfully."
        case let .configFileNotFound(fileName):
            return
                "Config file \(fileName) not found in the project path nor in the home directory. Default config will be used."
        case let .failedToReadFile(error):
            return "Failed to read file: \(error)"
        case let .wordIsMisspelled(
            path: path, line: line, column: column, severity: severity, word: word):
            return "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled !"
        case let .wordIsMisspelledWithSuggestions(
            path: path,
            line: line,
            column: column,
            severity: severity,
            word: word,
            suggestions: suggestions):
            return
                "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled, do you mean \(suggestions.map { "'\($0)'" }.joined(separator: ", ")) ?"
        case let .genericError(error):
            return "Error: \(error)"
        case let .failedToCreateConfigFile(fileName, error):
            return "Error creating \(fileName) config file: \(error)"
        case let .duplicatesInIgnoreList(duplicates):
            let isManyWords = duplicates.count > 1
            return
                "The following word\(isManyWords ? "s" : "") \(isManyWords ? "are" : "is") duplicated in the ignore list and can be removed: \(duplicates.joined(separator: ", "))"
        case let .capitalizedPairsInIgnoreList(pairs):
            return "The following word pairs exist in both lowercase and capitalized forms: "
                + pairs.map { "\($0.0) and \($0.1)" }.joined(separator: ", ")
                + ". The lowercase version is sufficient for \(Constants.name)."
        case let .configLoadingError(error):
            return "Error loading configuration: \(error)"
        case let .unknownRule(rule):
            return "Unknown rule: \(rule)"
        case let .doneChecking(misspelledWordsNumber, elapsedTime):
            return
                "Done checking! Found \(misspelledWordsNumber) misspelled words. Processing took \(elapsedTime) seconds."
        case .success:
            return ""
        case let .doneCheckingAndCorrecting(misspelledWordsNumber, correctedWordsNumber, elapsedTime):
            return "Done checking and correcting! Found \(misspelledWordsNumber) misspelled words. Corrected \(correctedWordsNumber) Words. Processing took \(elapsedTime) seconds."
        }
    }
    
    static let negativeContraction = "n't"
    static let validVerbs = ["are", "is", "was", "were", "have", "has", "had", "do", "does", "did", "can", "could", "shall", "should", "will", "would", "may", "might", "must"]
    static let pronounContractions = ["'m", "'re", "'s", "'ve", "'ll", "'d"]
    static let validPronouns = ["i", "you", "he", "she", "it", "we", "they"]
    static let specificContractions = ["ain't", "y'all", "o'clock"]

    static let swiftKeywords = [
        "associatedtype", "deinit", "fileprivate", "rethrows", "typealias", "fallthrough",
        "nonmutating"
    ]

    static let htmlTags = [
        "nav", "div", "span", "ul", "li", "ol",
        "br", "thead", "tbody", "tr", "td", "th",
        "svg"
    ]

    static let shortenedWords = [
        "img", "imgs", "arr", "curr", "attr", "attrs",
        "attribs", "btn", "txt", "lbl", "cfg", "usr",
        "num", "err", "msg", "pwd", "val", "max",
        "min", "info", "nav", "dir", "dirs", "idx",
        "elem", "tmp", "impl", "params", "auth", "utils",
        "gen", "bg", "buf", "faq", "arch", "archs",
        "expr", "ctx", "grp", "addr", "dst", "proj",
        "enc", "env", "envs", "attrib", "subdir", "iter",
        "inf", "nb", "nbr", "ptr", "dic", "dict", "config"
    ]

    static let commonlyUsedWords = [
        "codable", "hashable", "iterable", "diffable", "lhs", "rhs",
        "usleep", "autoreleasepool", "cancellables", "qos", "xcode", "spi",
        "sut", "xcodebuild", "iphone", "ipad", "xcpretty", "tuist",
        "md5", "sha1", "pkcs12", "eof", "nio", "ipv4",
        "ipv6", "yyyy", "ss", "md", "js", "cer", "ttf", "otf",
        "ws", "wss", "iphoneos", "utf", "utf8", "utf16",
        "ios", "dylib", "swiftlang", "xcodeproj", "xcworkspace", "swiftgen",
        "swiftlint", "swiftformat", "swiftyspell",
        "rswift", "xcconfig", "sourcery", "xlinker", "xcframework", "iboutlet",
        "ibinspectable", "ibdesignable", "xcframeworks", "sdk", "protobuf", "alamofire",
        "grpc", "momd", "moya", "utc", "crlf", "deinitialized",
        "deinitialization", "xctest", "xcprivacy", "nonobjc", "sha256", "ocr",
        "nfc", "opencv", "rgb", "rgba", "rtl", "ltr",
        "csv", "graphql", "sqrt", "kotlin", "gradle", "nodoc",
        "recaptcha", "yml", "toml", "linuxmain", "rfc", "ns",
        "nsrange", "nserror", "nsobject", "nsstring", "linting", "netrc",
        "whoami", "aarch64", "macosx", "pkg", "Onone", "lproj",
        "uid", "io", "xcassets", "oauth", "heic", "zlib",
        "foobar", "corelibs", "unkeyed", "inlinable", "utf32",
        "rethrow", "sha512", "bcrypt", "rx", "reactivex", "xcrun",
        "lipo", "xcscheme", "xcarchive", "armv7", "simctl", "otool",
        "iphonesimulator", "appletvos", "interactor", "jwt", "csrf", "iot",
        "crashlytics", "qr", "mqtt", "hunspell", "uikit", "otp"
    ]

    static let loremIpsumWords = [
        "lorem", "ipsum", "dolor", "sit", "amet", "consectetur",
        "adipiscing", "elit", "sed", "do", "eiusmod", "tempor",
        "incididunt", "ut", "labore", "et", "dolore", "magna",
        "aliqua", "ut", "enim", "ad", "minim", "veniam",
        "quis", "nostrud", "exercitation", "ullamco", "laboris", "nisi",
        "ut", "aliquip", "ex", "ea", "commodo", "consequat",
        "duis", "aute", "irure", "dolor", "in", "reprehenderit",
        "in", "voluptate", "velit", "esse", "cillum", "dolore",
        "eu", "fugiat", "nulla", "pariatur", "excepteur", "sint",
        "occaecat", "cupidatat", "non", "proident", "sunt", "in",
        "culpa", "qui", "officia", "deserunt", "mollit", "anim",
        "id", "est", "laborum", "curabitur", "pretium", "tincidunt",
        "lacus", "suspendisse", "potenti", "ut", "pharetra", "augue",
        "nec", "augue", "nam", "elit", "magna", "hendrerit",
        "sit", "amet", "tincidunt", "ac", "viverra", "sed",
        "nulla", "donec", "porta", "diam", "eu", "massa"
    ]

    static let otherWordPatterns = [
        "^(?i)RFC\\d+$"
    ]
}
