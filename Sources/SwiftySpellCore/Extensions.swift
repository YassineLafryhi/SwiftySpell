//
//  Extensions.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import SwiftSyntax

extension String {
    func matches(_ pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }

    func replace(_ target: String, _ replacement: String) -> String {
        replacingOccurrences(of: target, with: replacement)
    }

    func remove(_ substring: String) -> String {
        replacingOccurrences(of: substring, with: String())
    }

    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trimLastNumbers() -> String {
        replacingOccurrences(of: "\\d+$", with: String(), options: .regularExpression)
    }

    func endsWith(_ suffix: String) -> Bool {
        hasSuffix(suffix)
    }
}

extension SyntaxProtocol {
    var isContainedInFunctionBody: Bool {
        var current: SyntaxProtocol? = self
        while let currentNode = current {
            if Syntax(currentNode).asProtocol(SyntaxProtocol.self) is FunctionDeclSyntax {
                return true
            }
            current = currentNode.parent
        }
        return false
    }
}
