// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftySpell",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwiftySpellCore", targets: ["SwiftySpellCore"]),
        .executable(name: "swiftyspell", targets: ["SwiftySpellCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "600.0.1"),
        .package(url: "https://github.com/jpsim/Yams.git", exact: "5.1.3"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.5.0")
    ],
    targets: [
        .systemLibrary(
            name: "CHunspell",
            pkgConfig: "hunspell",
            providers: [
                .brew(["hunspell"])
            ]),
        .target(
            name: "SwiftySpellCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                "Yams",
                "CHunspell"
            ]),
        .executableTarget(
            name: "SwiftySpellCLI",
            dependencies: [
                "SwiftySpellCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "SwiftySpellTests",
            dependencies: ["SwiftySpellCLI", "SwiftySpellCore"])
    ])
