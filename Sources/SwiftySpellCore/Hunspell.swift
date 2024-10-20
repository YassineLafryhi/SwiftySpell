//
//  Hunspell.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 14/10/2024.
//

#if os(Linux)
import CHunspell
import Foundation

public class Hunspell {
    private var handle: OpaquePointer?

    public init?(affixFilePath: String, dictionaryFilePath: String) {
        handle = Hunspell_create(affixFilePath, dictionaryFilePath)
    }

    deinit {
        if let handle = handle {
            Hunspell_destroy(handle)
        }
    }

    public func spell(_ word: String) -> Bool {
        Hunspell_spell(handle, word) != 0
    }

    public func suggest(_ word: String) -> [String] {
        var suggestionPtr: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
        let count = Hunspell_suggest(handle, &suggestionPtr, word)

        guard let suggestionList = suggestionPtr else {
            return []
        }

        var suggestions: [String] = []
        for i in 0 ..< count {
            if let suggestion = suggestionList[Int(i)] {
                suggestions.append(String(cString: suggestion))
            }
        }

        Hunspell_free_list(handle, &suggestionPtr, Int32(count))
        return suggestions
    }
}
#endif
