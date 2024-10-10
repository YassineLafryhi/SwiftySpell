//
//  HunspellWrapper.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/10/2024.
//

import Foundation

class HunspellWrapper {
    private let hunspellPath = "/opt/homebrew/bin/hunspell"
    private let dictionaryPath = "Library/Spelling"

    func checkText(_ text: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: hunspellPath)
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        process.arguments = ["-d", homeDirectory.appendingPathComponent(dictionaryPath).path, "-a"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()

            let inputHandle = inputPipe.fileHandleForWriting
            inputHandle.write(text.data(using: .utf8)!)
            inputHandle.closeFile()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Error: Could not read output"

            process.waitUntilExit()

            return parseHunspellOutput(output)
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    private func parseHunspellOutput(_ output: String) -> String {
        let lines = output.split(separator: "\n")
        var result = ""

        for line in lines {
            if line.starts(with: "&") || line.starts(with: "#") {
                let parts = line.split(separator: " ", maxSplits: 4)
                if parts.count >= 4 {
                    let word = parts[1]
                    let suggestions = parts[3...].joined(separator: " ")
                    result += "Misspelled word: \(word)\n"
                    result += "Suggestions: \(suggestions)\n\n"
                }
            }
        }

        return result.isEmpty ? "No spelling errors found." : result
    }
}
