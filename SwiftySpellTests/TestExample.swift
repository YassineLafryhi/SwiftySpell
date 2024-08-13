//
//  TestExample.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 13/8/2024.
//

import Foundation

internal enum Accesibility {
    case alow
    case privilige
    case acheive
    case recieve
}

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

var occurenceCount = 0

internal func definateResult(for input: Int) -> Bool {
    input > 0
}
