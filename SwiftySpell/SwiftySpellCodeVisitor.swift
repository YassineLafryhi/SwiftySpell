//
//  SwiftySpellCodeVisitor.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/8/2024.
//

import Foundation
import SwiftSyntax

internal class SwiftySpellCodeVisitor: SyntaxVisitor {
    var variables: [(String, AbsolutePosition)] = []
    var globalOrConstantVariables: [(identifier: String, position: AbsolutePosition, kind: String)] = []
    var classes: [(String, AbsolutePosition)] = []
    var structs: [(String, AbsolutePosition)] = []
    var functions: [(String, AbsolutePosition)] = []
    var strings: [(String, AbsolutePosition)] = []
    var enums: [(String, AbsolutePosition)] = []
    var typeAliases: [(String, AbsolutePosition)] = []
    var protocols: [(String, AbsolutePosition)] = []
    var extensions: [(String, AbsolutePosition)] = []
    var functionParameters: [(String, AbsolutePosition)] = []

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let protocolName = node.identifier.text
        let position = node.position
        protocols.append((protocolName, position))
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let extendedTypeName = node.extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let position = node.position
        extensions.append((extendedTypeName, position))
        return .visitChildren
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.identifier.text
        let position = node.position
        typeAliases.append((typeName, position))
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let enumName = node.identifier.text
        let position = node.position
        enums.append((enumName, position))
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            switch binding.pattern {
            case let identifierPattern:
                let position = identifierPattern.position
                variables.append((identifierPattern.description, position))
            }
        }

        let isGlobalOrConstant = !node.isContainedInFunctionBody

        if isGlobalOrConstant {
            for binding in node.bindings {
                if let identifier = binding.pattern.firstToken?.text {
                    let position = binding.position
                    let kind = node.letOrVarKeyword.text
                    globalOrConstantVariables.append((identifier, position, kind))
                }
            }
        }

        return .visitChildren
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let stringLiteral = node.description.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let position = node.position
        strings.append((stringLiteral, position))
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.identifier.text
        let position = node.position
        classes.append((className, position))
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let structName = node.identifier.text
        let position = node.position
        structs.append((structName, position))
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.identifier.text
        if isCFunction(name: functionName) {
            return .skipChildren
        }

        let position = node.position
        functions.append((functionName, position))

        for parameter in node.signature.input.parameterList {
            let paramName = parameter.firstName?.text ?? ""
            let position = parameter.position
            functionParameters.append((paramName, position))
        }

        return .visitChildren
    }

    private func isCFunction(name: String) -> Bool {
        name.hasPrefix("c_") || name.hasPrefix("C_")
    }
}
