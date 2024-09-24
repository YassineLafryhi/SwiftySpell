//
//  Constants.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation

internal class Constants {
    static let name = "SwiftySpell"
    static let currentVersion = "0.9.6"
    static let configFileName = ".swiftyspell.yml"

    static let defaultLanguage = "en"
    static let languageCodeOfBritishEnglish = "en_GB"
    static let defaultExcludedDirectories = ["Pods"]
    static let defaultExcludedFiles = ["Package.swift"]

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
          - ignore_other_words
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
    static let newLineCharacter = "\\n"
    static let tabCharacter = "\\t"
    static let possessiveApostrophe = "'"
    static let possessiveMarker = "s"
    static let swiftFileExtension = "swift"
    static let regexSymbols = "[.^$*+?()\\[\\]{}|\\\\]"
    static let letSwiftKeyword = "let"
    static let varSwiftKeyword = "var"

    enum MessageType {
        case projectPathDoesNotExist
        case genericError(_ error: String)
        case configFileCreatedSuccessfully(_ fileName: String)
        case failedToCreateConfigFile(_ fileName: String, _ error: String)
        case configFileNotFound(_ fileName: String)
        case failedToReadFile(_ error: String)
        case wordIsMisspelled(path: String, line: Int, column: Int, severity: Severity, word: String)
        case wordIsMisspelledWithSuggestions(
            path: String,
            line: Int,
            column: Int,
            severity: Severity,
            word: String,
            suggestions: [String])
        case duplicatesInIgnoreList(_ duplicates: Set<String>)
        case capitalizedPairsInIgnoreList(_ pairs: [(String, String)])
        case configLoadingError(_ error: String)
        case unknownRule(_ rule: String)
    }

    static func getMessage(_ message: MessageType) -> String {
        switch message {
        case .projectPathDoesNotExist:
            "The given project path does not exist."
        case let .configFileCreatedSuccessfully(fileName):
            "\(fileName) config file has been created successfully."
        case let .configFileNotFound(fileName):
            "Config file \(fileName) not found in the project path nor in the home directory. Default config will be used."
        case let .failedToReadFile(error):
            "Failed to read file: \(error)"
        case let .wordIsMisspelled(path: path, line: line, column: column, severity: severity, word: word):
            "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled !"
        case let .wordIsMisspelledWithSuggestions(
            path: path,
            line: line,
            column: column,
            severity: severity,
            word: word,
            suggestions: suggestions):
            "\(path):\(line):\(column): \(severity): '\(word)' may be misspelled, do you mean \(suggestions.map { "'\($0)'" }.joined(separator: ", ")) ?"
        case let .genericError(error):
            "Error: \(error)"
        case let .failedToCreateConfigFile(fileName, error):
            "Error creating \(fileName) config file: \(error)"
        case let .duplicatesInIgnoreList(duplicates):
            "The following words are duplicated in the ignore list and can be removed: \(duplicates.joined(separator: ", "))"
        case let .capitalizedPairsInIgnoreList(pairs):
            "The following word pairs exist in both lowercase and capitalized forms: " +
                pairs.map { "\($0.0) and \($0.1)" }.joined(separator: ", ") +
                ". The lowercase version is sufficient for \(Constants.name)."
        case let .configLoadingError(error):
            "Error loading configuration: \(error)"
        case let .unknownRule(rule):
            "Unknown rule: \(rule)"
        }
    }

    static let supportingTerms = [
        "xterm-color", "xterm-256color", "screen", "screen-256color", "ansi", "linux", "vt100"
    ]

    enum ANSIColor: String {
        case black = "\u{001B}[0;30m"
        case red = "\u{001B}[0;31m"
        case green = "\u{001B}[0;32m"
        case yellow = "\u{001B}[0;33m"
        case blue = "\u{001B}[0;34m"
        case magenta = "\u{001B}[0;35m"
        case cyan = "\u{001B}[0;36m"
        case white = "\u{001B}[0;37m"
        case reset = "\u{001B}[0m"
        case teal = "\u{001B}[38;5;6m"
    }

    enum TextStyle {
        case normal
        case bold
    }

    enum Severity: String {
        case error
        case warning
    }

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
        "enc", "env", "envs", "attrib", "subdir", "iter"
    ]

    static let otherWords = [
        "codable", "hashable", "iterable", "diffable", "lhs", "rhs",
        "usleep", "autoreleasepool", "cancellables", "qos", "xcode", "spi",
        "sut", "xcodebuild", "iphone", "ipad", "xcpretty", "tuist",
        "md5", "sha1", "pkcs12", "eof", "nio", "ipv4",
        "ipv6", "yyyy", "ss", "md", "js", "cer", "ttf", "otf",
        "ws", "wss", "iphoneos", "utf", "utf8", "utf16",
        "ios", "dylib", "swiftlang", "xcodeproj", "xcworkspace", "swiftgen",
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
        "crashlytics", "qr"
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
