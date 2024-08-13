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
}

extension SyntaxProtocol {
    var isContainedInFunctionBody: Bool {
        var current: SyntaxProtocol? = self
        while let currentNode = current {
            if currentNode.as(Syntax.self)?.asProtocol(SyntaxProtocol.self) is FunctionDeclSyntax {
                return true
            }
            current = currentNode.parent
        }
        return false
    }
}
