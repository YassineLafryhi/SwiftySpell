import Foundation
import ProjectDescription

let name = "SwiftySpell"

let setupGitHooks = TargetScript.pre(
    script: readFromFile(.relativeToRoot("Scripts/BuildPhases/setup-git-hooks.sh")),
    name: "Setup Git Hooks",
    basedOnDependencyAnalysis: false)

let runSwiftFormat = TargetScript.pre(
    script: readFromFile(.relativeToRoot("Scripts/BuildPhases/run-swiftformat.sh")),
    name: "Format Code With SwiftFormat",
    basedOnDependencyAnalysis: false)

let runSwiftLint = TargetScript.pre(
    script: readFromFile(.relativeToRoot("Scripts/BuildPhases/run-swiftlint.sh")),
    name: "Lint Code With SwiftLint",
    basedOnDependencyAnalysis: false)

let runSwiftySpell = TargetScript.pre(
    script: readFromFile(.relativeToRoot("Scripts/BuildPhases/run-swiftyspell.sh")),
    name: "Check Spelling With SwiftySpell",
    basedOnDependencyAnalysis: false)

let runPeriphery = TargetScript.pre(
    script: readFromFile(.relativeToRoot("Scripts/BuildPhases/run-periphery.sh")),
    name: "Identify Unused Code With Periphery",
    basedOnDependencyAnalysis: false)

let project = Project(
    name: name,
    packages: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.9.1")
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "55DHYS5FJZ"
        ]),
    targets: [
        .target(
            name: name,
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "io.github.yassinelafryhi.\(name)",
            sources: ["\(name)/Sources/**"],
            scripts: [
                setupGitHooks,
                runSwiftFormat,
                runSwiftLint,
                runSwiftySpell,
                runPeriphery
            ],
            dependencies: [
                .package(product: "SwiftSyntax"),
                .package(product: "SwiftSyntaxParser"),
                .package(product: "Yams"),
                .package(product: "Commander")
            ])
    ])

func readFromFile(_ path: ProjectDescription.Path) -> String {
    let fileURL = URL(fileURLWithPath: path.pathString)
    let content = try! String(contentsOf: fileURL, encoding: .utf8)
    return content
}
