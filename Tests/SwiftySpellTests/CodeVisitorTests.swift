//
//  CodeVisitorTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

import SwiftParser
import SwiftSyntax
import XCTest
@testable import SwiftySpellCore

final class CodeVisitorTests: XCTestCase {
    var visitor: CodeVisitor!

    override func setUp() {
        super.setUp()
        visitor = CodeVisitor(viewMode: .all)
    }

    func testVisitProtocol() {
        let source = "protocol TestProtocol {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.protocols.count, 1)
        XCTAssertEqual(visitor.protocols[0].0, "TestProtocol")
    }

    func testVisitExtension() {
        let source = "extension String {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.extensions.count, 1)
        XCTAssertEqual(visitor.extensions[0].0, "String")
    }

    func testVisitTypeAlias() {
        let source = "typealias MyInt = Int"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.typeAliases.count, 1)
        XCTAssertEqual(visitor.typeAliases[0].0, "MyInt")
    }

    func testVisitEnum() {
        let source = """
            enum TestEnum {
                case firstCase
                case secondCase(name: String)
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.enums.count, 1)
        XCTAssertEqual(visitor.enumCases.count, 2)
        XCTAssertEqual(visitor.enumCases[0].0, "firstCase")
        XCTAssertEqual(visitor.enumCases[1].0, "secondCase")
        XCTAssertEqual(visitor.enumCasesAssociatedValues.count, 1)
        XCTAssertEqual(visitor.enumCasesAssociatedValues[0].0, "name")
    }

    func testVisitVariable() {
        let source = """
            let globalVar = 10
            func test() {
                var localVar = 20
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.variables.count, 2)
        XCTAssertEqual(visitor.globalOrConstantVariables.count, 1)
        XCTAssertEqual(visitor.globalOrConstantVariables[0].identifier, "globalVar")
    }

    func testVisitStringLiteral() {
        let source = """
            let str = "Hello, World!"
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.strings.count, 1)
    }

    func testVisitClass() {
        let source = "class TestClass {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.classes.count, 1)
    }

    func testVisitStruct() {
        let source = "struct TestStruct {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.structs.count, 1)
        XCTAssertEqual(visitor.structs[0].0, "TestStruct")
    }

    func testVisitFunction() {
        let source = "func testFunc(param1: Int, param2: String) {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.functions.count, 1)
        XCTAssertEqual(visitor.functionParameters.count, 2)
        XCTAssertEqual(visitor.functionParameters[0].0, "param1")
        XCTAssertEqual(visitor.functionParameters[1].0, "param2")
    }

    func testVisitClosure() {
        let source = "let closure = { (x: Int) -> Int in return x * 2 }"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.closures.count, 1)
    }

    func testVisitInitializer() {
        let source = """
            struct Test {
                init(param: Int) {}
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.initializers.count, 1)
        XCTAssertEqual(visitor.functionParameters.count, 1)
        XCTAssertEqual(visitor.functionParameters[0].0, "param")
    }

    func testVisitSubscript() {
        let source = """
            struct Test {
                subscript(index: Int) -> Int {
                    return index
                }
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.subscripts.count, 1)
    }

    func testVisitGenericParameter() {
        let source = "func genericFunc<T>() {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.genericTypeParameters.count, 1)
    }

    func testVisitAttribute() {
        let source = "@available(iOS 13.0, *) func test() {}"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.attributes.count, 1)
    }

    func testVisitOperator() {
        let source = "infix operator +-: AdditionPrecedence"
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.customOperators.count, 1)
    }

    func testVisitThrowStatement() {
        let source = """
            func throwingFunc() throws {
                throw NSError(domain: "", code: 0)
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.throwStatements.count, 1)
    }

    func testVisitCatchClause() {
        let source = """
            do {
                try someThrowingFunc()
            } catch {
                print(error)
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.catchClauses.count, 1)
    }

    func testVisitGuardStatement() {
        let source = """
            func test() {
                guard let value = optionalValue else { return }
            }
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.guardStatementsVariables.count, 1)
        XCTAssertEqual(visitor.guardStatementsVariables[0].0, "value")
        XCTAssertEqual(visitor.guardStatementsValues.count, 1)
        XCTAssertEqual(visitor.guardStatementsValues[0].0, "optionalValue")
    }

    func testVisitDictionaryElement() {
        let source = """
            let dict = ["key1": "value1", "key2": "value2"]
            """
        let syntax = Parser.parse(source: source)
        visitor.walk(syntax)

        XCTAssertEqual(visitor.dictionaryKeys.count, 2)
        XCTAssertEqual(visitor.dictionaryKeys[0].0, "key1")
        XCTAssertEqual(visitor.dictionaryKeys[1].0, "key2")
        XCTAssertEqual(visitor.dictionaryValues.count, 2)
        XCTAssertEqual(visitor.dictionaryValues[0].0, "value1")
        XCTAssertEqual(visitor.dictionaryValues[1].0, "value2")
    }

    func testExtractOneLineComments() {
        let tempDir = FileManager.default.temporaryDirectory
        let filePath = tempDir.appendingPathComponent("testFile.swift").path
        let fileContent = """
            // This is a comment
            let x = 5 // This is another comment
            // Created by User on 1/1/2024
            // Copyright © 2024 Company. All rights reserved.
            """
        try! fileContent.write(toFile: filePath, atomically: true, encoding: .utf8)

        visitor.extractOneLineComments(from: filePath)

        XCTAssertEqual(visitor.oneLineComments.count, 2)
        XCTAssertEqual(visitor.oneLineComments[0].0, "This is a comment")
        XCTAssertEqual(visitor.oneLineComments[1].0, "This is another comment")
    }

    func testExtractMultiLineComments() {
        let tempDir = FileManager.default.temporaryDirectory
        let filePath = tempDir.appendingPathComponent("testFile.swift").path
        let fileContent = """
            /*
             This is a multi-line comment
             It spans multiple lines
            */
            let x = 5
            /*
             Another multi-line comment
            */
            /* This is a third multi-line comment.
            It contains 3 lines.
            And it starts directly the comment after the marker */
            """
        try! fileContent.write(toFile: filePath, atomically: true, encoding: .utf8)

        visitor.extractMultiLineComments(from: filePath)

        XCTAssertEqual(visitor.multiLineComments.count, 3)
        XCTAssertEqual(visitor.multiLineComments[0].count, 2)
        XCTAssertEqual(visitor.multiLineComments[1].count, 1)
        XCTAssertEqual(visitor.multiLineComments[2].count, 3)
    }
}
