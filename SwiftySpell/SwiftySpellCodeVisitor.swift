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
    var globalOrConstantVariables:
        [(identifier: String, position: AbsolutePosition, kind: String)] = []
    var classes: [ClassDeclSyntax] = []
    var structs: [(String, AbsolutePosition)] = []
    var functions: [FunctionDeclSyntax] = []
    var strings: [StringLiteralExprSyntax] = []
    var enums: [EnumDeclSyntax] = []
    var enumCases: [(String, AbsolutePosition)] = []
    var enumCasesAssociatedValues: [(String, AbsolutePosition)] = []
    var typeAliases: [(String, AbsolutePosition)] = []
    var protocols: [(String, AbsolutePosition)] = []
    var extensions: [(String, AbsolutePosition)] = []
    var functionParameters: [(String, AbsolutePosition)] = []
    var closures: [ClosureExprSyntax] = []
    var initializers: [InitializerDeclSyntax] = []
    var subscripts: [SubscriptDeclSyntax] = []
    var genericTypeParameters: [GenericParameterSyntax] = []
    var attributes: [AttributeSyntax] = []
    var customOperators: [OperatorDeclSyntax] = []
    var throwStatements: [ThrowStmtSyntax] = []
    var catchClauses: [CatchClauseSyntax] = []
    var guardStatementsVariables: [(String, AbsolutePosition)] = []
    var guardStatementsValues: [(String, AbsolutePosition)] = []
    var dictionaryKeys: [(String, AbsolutePosition)] = []
    var dictionaryValues: [(String, AbsolutePosition)] = []

    var oneLineComments: [(String, Int)] = []
    var multiLineComments: [[(String, Int)]] = []

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let protocolName = node.identifier.text
        let position = node.position
        protocols.append((protocolName, position))
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let extendedTypeName = node.extendedType.description.trimmingCharacters(
            in: .whitespacesAndNewlines)
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
        enums.append(node)
        return .visitChildren
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        for element in node.elements {
            let caseName = element.identifier.text
            let position = element.position
            enumCases.append((caseName, position))

            if let associatedValue = element.associatedValue {
                for parameter in associatedValue.parameterList {
                    if let firstName = parameter.firstName?.text {
                        let position = parameter.position
                        enumCasesAssociatedValues.append((firstName, position))
                    }

                    if let secondName = parameter.secondName?.text {
                        let position = parameter.position
                        enumCasesAssociatedValues.append((secondName, position))
                    }
                }
            }
        }
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
        // let stringLiteral = node.description.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        // let position = node.position
        strings.append(node)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        classes.append(node)
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let structName = node.identifier.text
        let position = node.position
        structs.append((structName, position))
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        functions.append(node)

        for parameter in node.signature.input.parameterList {
            if let argumentLabel = parameter.firstName?.text {
                let position = parameter.position
                functionParameters.append((argumentLabel, position))
            }

            if let parameterName = parameter.secondName?.text {
                let position = parameter.position
                functionParameters.append((parameterName, position))
            }
        }

        return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        closures.append(node)
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        initializers.append(node)

        for parameter in node.signature.input.parameterList {
            let paramName = parameter.firstName?.text ?? ""
            let position = parameter.position
            functionParameters.append((paramName, position))
        }

        return .visitChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        subscripts.append(node)
        return .visitChildren
    }

    override func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
        genericTypeParameters.append(node)
        return .visitChildren
    }

    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        attributes.append(node)
        return .visitChildren
    }

    override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        customOperators.append(node)
        return .visitChildren
    }

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        throwStatements.append(node)
        return .visitChildren
    }

    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        catchClauses.append(node)
        return .visitChildren
    }

    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        for condition in node.conditions {
            if let optionalBinding = condition.condition.as(OptionalBindingConditionSyntax.self) {
                let unwrappedName = optionalBinding.pattern.description.trimmingCharacters(
                    in: .whitespaces)
                let position = optionalBinding.position
                guardStatementsVariables.append((unwrappedName, position))

                if let initializerValue = optionalBinding.initializer?.value {
                    let valueName = initializerValue.description.trimmingCharacters(
                        in: .whitespaces)
                    let position = initializerValue.position
                    guardStatementsValues.append((valueName, position))
                }
            }
        }

        return .visitChildren
    }

    override func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
        for element in node {
            let keyName = element.keyExpression.description.trimmingCharacters(
                in: CharacterSet(charactersIn: "\""))
            let keyPosition = element.keyExpression.position
            dictionaryKeys.append((keyName, keyPosition))

            let valueName = element.valueExpression.description.trimmingCharacters(
                in: CharacterSet(charactersIn: "\""))
            let valuePosition = element.valueExpression.position
            dictionaryValues.append((valueName, valuePosition))
        }
        return .visitChildren
    }

    func extractOneLineComments(from filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        guard let fileContent = try? String(contentsOf: fileURL) else {
            Utilities.printError("Failed to read file !")
            return
        }
        let lines = fileContent.components(separatedBy: .newlines)
        var lineNumber = 0

        for line in lines {
            lineNumber += 1
            if line.contains("//") {
                var comment = line
                if line.hasPrefix("// ") {
                    comment = String(line.dropFirst(3))
                }
                oneLineComments.append((comment.trimmingCharacters(in: .whitespacesAndNewlines), lineNumber))
            }
        }
    }

    func extractMultiLineComments(from filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        guard let fileContent = try? String(contentsOf: fileURL) else {
            Utilities.printError("Failed to read file !")
            return
        }
        let lines = fileContent.components(separatedBy: .newlines)
        var lineNumber = 0
        var multiLineComment = [(String, Int)]()
        var isMultiLineComment = false

        for line in lines {
            lineNumber += 1
            if line.contains("/*") {
                isMultiLineComment = true
                multiLineComment.append((line, lineNumber))
            }

            if isMultiLineComment {
                multiLineComment.append((line, lineNumber))
            }

            if line.contains("*/") {
                isMultiLineComment = false
                multiLineComments.append(multiLineComment)
            }
        }
    }
}
