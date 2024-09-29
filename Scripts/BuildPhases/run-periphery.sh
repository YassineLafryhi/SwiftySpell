if [[ "$(uname -m)" == arm64 ]]
then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if [ -f "/tmp/skip_periphery.txt" ]; then
    rm -f "/tmp/skip_periphery.txt"
    exit 0
fi
touch "/tmp/skip_periphery.txt"
periphery scan
