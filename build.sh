#!/bin/bash

build_macos() {
    echo "Building for macOS..."

    swift build -c release -Xswiftc -Osize --arch arm64
    swift build -c release -Xswiftc -Osize --arch x86_64

    local arm64_binary=".build/arm64-apple-macosx/release/swiftyspell"
    local x86_64_binary=".build/x86_64-apple-macosx/release/swiftyspell"
    local universal_binary="./swiftyspell"

    lipo -create -output "$universal_binary" "$arm64_binary" "$x86_64_binary"
    echo "Universal binary created at $universal_binary"

    strip "$universal_binary"

    lipo -info "$universal_binary"
}

build_linux() {
    echo "Building for Linux..."

    swift build -c release -Xswiftc -Osize --static-swift-stdlib
    mv ./.build/release/swiftyspell ./swiftyspell

    strip ./swiftyspell
}

OS=$(uname -s)

case "$OS" in
    Darwin)
        build_macos
        ;;
    Linux)
        build_linux
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac
