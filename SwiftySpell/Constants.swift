//
//  Constants.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation

internal class Constants {
    static let currentVersion = "0.9.6"
    static let configFileName = ".swiftyspell.yml"

    static let supportingTerms = ["xterm-color", "xterm-256color", "screen", "screen-256color", "ansi", "linux", "vt100"]

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
}
