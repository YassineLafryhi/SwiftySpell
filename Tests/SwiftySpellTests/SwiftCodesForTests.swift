//
//  SwiftCodesForTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

internal class SwiftCodesForTests {
    let code: String
    let misspelledWords: [String]

    public init(code: String, misspelledWords: [String]) {
        self.code = code
        self.misspelledWords = misspelledWords
    }

    public static func forVariables() -> SwiftCodesForTests {
        let code = """
            var occurenceCount = 0
            """
        let misspelledWords = ["occurence"]
        return .init(code: code, misspelledWords: misspelledWords)
    }
    
    public static func forStrings() -> SwiftCodesForTests {
        let code = """
            var firstString = "This is a misppeled text"
            firstString = "There is no spelling error in these words: isn't, aren't, wasn't, weren't, don't, doesn't, didn't, hasn't, haven't, hadn't, I'm, you're, they're, we're, he's, she's, it's, I've, you've, they've, I'll, you'll, they'll, I'd, you'd, they'd"
            firstString = "the config is sucessfuly checked"
            """
        let misspelledWords = ["misppeled", "sucessfuly"]
        return .init(code: code, misspelledWords: misspelledWords)
    }

    public static func forEnumCases() -> SwiftCodesForTests {
        let code = """
            internal enum Accesibility {
                case privilige
                case acheive

                enum NesstedEnum {
                    case firstCasse(imdex: Int)

                    enum VearyNestedEnum {
                        case tirdCase
                    }
                }
            }
            """
        let misspelledWords = [
            "Accesibility",
            "privilige",
            "acheive",
            "Casse",
            "imdex",
            "Veary",
            "Nessted",
            "tird"
        ]
        return .init(code: code, misspelledWords: misspelledWords)
    }

    public static func forComments() -> SwiftCodesForTests {
        let code = """
            // This is a one linne comment with some speling mistakes

            // This is a annother one line comment with morre spelling mistakes

            /*
             * This is an exmaple of a multiline comment with some speling mistakes,
             * in diferent lines, that are also dettected.
             */
            """
        let misspelledWords = [
            "linne",
            "speling",
            "annother",
            "morre",
            "speling",
            "exmaple",
            "diferent",
            "dettected"
        ]
        return .init(code: code, misspelledWords: misspelledWords)
    }

    public static func forClassWithAttributes() -> SwiftCodesForTests {
        let code = """
            internal class Testt {
                var assigment: String
                var calenderDate: Date

                init(assigment: String, calenderDate: Date) {
                    self.assigment = assigment
                    self.calenderDate = calenderDate
                }
            }
            """
        let misspelledWords = ["Testt", "assigment", "calender", "assigment", "calender"]
        return .init(code: code, misspelledWords: misspelledWords)
    }

    public static func forClassWithEnumsAndFunctions() -> SwiftCodesForTests {
        let code = """
            internal class Test {

                func retreiveData() {
                }

                func proccessData(imput: String) {
                }

                func maintanenceCheck() {
                    print("Performing maintanence check...")
                }

                enum TestMannager {
                    struct TestMannager {}
                }

                class TestMannagger {}
            }
            """
        let misspelledWords = [
            "retreive",
            "imput",
            "proccess",
            "maintanence",
            "maintanence",
            "Mannager",
            "Mannager",
            "Mannagger"
        ]
        return .init(code: code, misspelledWords: misspelledWords)
    }

    public static func forArraysAndDictionaries() -> SwiftCodesForTests {
        let code = """
            func arrayExample() -> [String] {
                ["speling", "erors", "are", "evrywhere"]
            }

            func dictionaryExample() -> [String: Int] {
                ["onne": 1, "two": 2, "thre": 3]
            }
            """
        let misspelledWords = ["speling", "erors", "evrywhere", "onne", "thre"]
        return .init(code: code, misspelledWords: misspelledWords)
    }

    public static func forManyCodeSegments() -> SwiftCodesForTests {
        let code = """
            class SubscriptExample {
                subscript(imdex: Int) -> Int {
                    imdex * 2
                }
            }

            func genericFunction<Tenplate>(value: Tenplate) -> Tenplate {
                value
            }



            internal func definateResult(for input: Int) -> Bool {
                input > 0
            }

            let wordsInBritishEnglish = ["colour", "jewellery", "analyse", "defence", "aluminium"]

            // let language = "arabic"

            let swiftKeywords = [
                "associatedtype", "deinit", "fileprivate", "rethrows", "typealias", "fallthrough", "nonmutating"
            ]

            let company = "microsoft"
            let firstname = "Adam"
            let text1 = "heHas1bookWith300pages"
            let text2 = "Alamofire's work is awesome"

            /// Represents a user in the system.
            ///
            /// Conforms to `Codable`, `Hashable`, `Equatable`, `Comparable`, `Identifiable`, and contains a role that is iterable.
            struct User: Codable, Hashable, Equatable, Comparable, Identifiable {
                var id: UUID
                var name: String
                var email: String
                var age: Int
                var role: Role

                /// Represents the role of a user.
                ///
                /// Conforms to `CaseIterable` and `Codable` for easy iteration and serialization.
                enum Role: String, CaseIterable, Codable {
                    case admin
                    case user
                    case guest
                }

                static func == (lhs: User, rhs: User) -> Bool {
                    lhs.id == rhs.id &&
                        lhs.name == rhs.name &&
                        lhs.email == rhs.email &&
                        lhs.role == rhs.role
                }

                static func < (lhs: User, rhs: User) -> Bool {
                    lhs.age < rhs.age
                }
            }

            """
        let misspelledWords = ["imdex", "Tenplate", "definate"]
        return .init(code: code, misspelledWords: misspelledWords)
    }
}
