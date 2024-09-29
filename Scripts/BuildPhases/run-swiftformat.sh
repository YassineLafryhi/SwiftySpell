if [[ "$(uname -m)" == arm64 ]]
then
    export PATH="/opt/homebrew/bin:$PATH"
fi

swiftformat "${SRCROOT}" --cache ignore
