//
//  LanguageToolWrapper.swift
//  SwiftySpell
//
//  Created by Yassine Lafryhi on 10/10/2024.
//

import Foundation

internal class LanguageToolWrapper {
    private let languageToolPath = "/opt/homebrew/bin/languagetool"

    func checkText(_ text: String, languageCode: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: languageToolPath)
        process.arguments = ["-l", languageCode, "-"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()

            let inputHandle = inputPipe.fileHandleForWriting
            if let data = text.data(using: .utf8) {
                inputHandle.write(data)
                inputHandle.closeFile()
            }
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Error: Could not read output"

            process.waitUntilExit()

            return output
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
