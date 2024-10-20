#!/bin/bash

get_next_version() {
    local version=$1
    local major minor patch

    IFS='.' read -r major minor patch <<< "${version#v}"

    if [ -z "$patch" ]; then
        echo "Error: Invalid version format. Expected v{major}.{minor}.{patch}"
        exit 1
    fi

    patch=$((patch + 1))
    echo "$major.$minor.$patch"
}

if [ -z "$1" ]; then
    echo "Version not provided. Fetching latest release from GitHub..."
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/YassineLafryhi/SwiftySpell/releases/latest | grep tag_name | cut -d '"' -f 4)

    if [ -z "$LATEST_RELEASE" ]; then
        echo "Error: Failed to fetch latest release version from GitHub."
        exit 1
    fi

    VERSION=$(get_next_version $LATEST_RELEASE)
    echo "Incrementing version. New version: $VERSION"
else
    VERSION=$1
fi

PROJECT_NAME="SwiftySpell"
BINARY_NAME="swiftyspell"
ZIP_FILE="$PROJECT_NAME-v$VERSION.zip"

if [ ! -f "./$BINARY_NAME" ]; then
    echo "Error: $BINARY_NAME not found in the current directory. Please build the project first."
    exit 1
fi

echo "Binary $BINARY_NAME found. Proceeding with release..."

echo "Creating zip file..."
zip -r $ZIP_FILE $PROJECT_NAME

if [ $? -ne 0 ]; then
    echo "Error: Failed to zip the file."
    exit 1
fi

echo "Generating release notes..."
LATEST_TAG=$(git describe --tags --abbrev=0)
RELEASE_NOTES=$(git log ${LATEST_TAG}..HEAD --pretty=format:'%s' | grep -E '^(Feat|Fix):' | sed 's/^/+ /' | tail -r)
if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="No new features or fixes in this release."
fi

echo "Creating GitHub release and uploading zip..."
gh release create $VERSION "$ZIP_FILE" --title "$PROJECT_NAME v$VERSION" --notes "$RELEASE_NOTES"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create GitHub release."
    exit 1
fi

echo "Success: $PROJECT_NAME $VERSION has been released and uploaded to GitHub."
