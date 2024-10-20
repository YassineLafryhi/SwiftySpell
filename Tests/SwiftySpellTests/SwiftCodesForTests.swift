//
//  SwiftCodesForTests.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 12/10/2024.
//

internal class SwiftCodesForTests {
    let code: String
    let misspelledWords: [String]
    var correctedWords: [String] = []

    public init(code: String, misspelledWords: [String], correctedWords: [String] = []) {
        self.code = code
        self.misspelledWords = misspelledWords
        self.correctedWords = correctedWords
    }

    public static func forVariables() -> SwiftCodesForTests {
        let code = """
            var occurenceCount = 0
            """
        let misspelledWords = ["occurence"]
        return .init(code: code, misspelledWords: misspelledWords, correctedWords: ["occurrence"])
    }

    public static func forStrings() -> SwiftCodesForTests {
        let code = """
            var firstString = "This is a misppeled text"
            firstString = "There is no spelling error in these words: isn't, aren't, wasn't, weren't, don't, doesn't, didn't, hasn't, haven't, hadn't, I'm, you're, they're, we're, he's, she's, it's, I've, you've, they've, I'll, you'll, they'll, I'd, you'd, they'd"
            firstString = "the config is sucessfuly checked"
            firstString = "This] [book] is/ {very} //good"
            let nsError = error as NSError
            fatalError("Unresolved error \\(nsError), \\(nsError.userInfo)")

            Logger.shared.log("Web Server started at \\(webServer.serverURL ?? URL(string: "http://localhost:8080")!)")

            var secondString = \"""
                This is alsoo a text that contains some mistaks
            \"""
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

            enum Status: String {
                case active = "Actve"
                case inactive = "Inctive"
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
            "tird",
            "Actve",
            "Inctive"
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

            /// This fumction addds two nubres
            /// - Parameters:
            ///   - a: The frst numbber to add
            ///   - b: The second nuber to add
            func add(a: Int, b: Int) -> Int {
                retun a + b
            }
            """
        let misspelledWords = [
            "linne",
            "speling",
            "annother",
            "morre",
            "speling",
            "exmaple",
            "diferent",
            "dettected",
            "fumction",
            "addds",
            "nubres",
            "frst",
            "numbber",
            "nuber"
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

                class OthherTestClass {}
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
            "Othher"
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

            let response = "Not Found"
            switch response {
            case "OK":
                print("Everything is fine")
            case "Not Found":
                print("The requested resource was not foundd")
            default:
                print("Unknown status")
            }

            let json = "{\"keyy\": \"vallue\"}" // Example JSON

            let message = \"""
            The output recieved from the server is not correct.
            Please recheck the endpint and try again.
            \"""

            @available(iOS 14.0, *)
            func someMethod() {
                #warning("This is not optiimal for performncee")
            }

            let message = "An error has occured\nPlease check the input. \tThen retry"

            Text("Welcomme to the app, \\(userNname)!")
                .font(.title)
                .foregroundColor(.red)

            let query = QueryBuilder().where("userr_name", isEqualTo: "John").limit(10).excecute()


            func checkAgge(agee: Int?) {
                guard let validdAge = age, validdAge > 0 else {
                    print("Agge must be a positv number.")
                    return
                }

                print("The agee is \\(validdAge)")
            }

            func registerUser(username: String?, password: String?, email: String?) {
                guard let valiUsername = username,
                      let valdPassword = password,
                      let vaiddEmail = email else {
                    print("All fields must be filled out correctly.")
                    return
                }

                // Proceed with user registration
                print("Registering user with username: \\(validUsername), email: \\(validEmail)")
            }


            """
        let misspelledWords = ["imdex", "Tenplate", "definate"]
        return .init(code: code, misspelledWords: misspelledWords)
    }
}
