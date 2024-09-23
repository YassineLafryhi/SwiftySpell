//
//  TestExample.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 13/8/2024.
//

import Foundation

internal enum Accesibility {
    case allaw
    case privilige
    case acheive
    case recieve

    enum NesstedEnum {
        case firstCasse
        case secandCase(imdex: Int)

        enum VearyNesstedEnum {
            case tirdCasse
        }
    }
}

// This is a one linne comment with some speling mistakes

// This is a annother one line comment with morre spelling mistakes

/*
 * This is an exmaple of a multiline comment with some speling mistakes,
 * in diferent lines, that are also dettected by SwiftySpell.
 */

internal class Testt {
    var assigment: String
    var calenderDate: Date

    init(assigment: String, calenderDate: Date) {
        self.assigment = assigment
        self.calenderDate = calenderDate
    }

    func retreiveData() -> String {
        "Retreiving data for assigment: \(assigment)"
    }

    func proccessData(input: String) -> String {
        "Proccessing data: \(input)"
    }

    func maintanenceCheck() {
        print("Performing maintanence check...")
    }

    enum TestMannager {
        struct TestMannager {}
    }

    class TestMannagger {}
}

func arrayExample() -> [String] {
    ["speling", "erors", "evrywhere"]
}

func dictionaryExample() -> [String: Int] {
    ["onne": 1, "twoo": 2, "thre": 3]
}

class SubscriptExample {
    subscript(imdex: Int) -> Int {
        imdex * 2
    }
}

func genericFunction<Tenplate>(value: Tenplate) -> Tenplate {
    value
}

var occurenceCount = 0

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
let text = "heHas1bookWith300pages"

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
