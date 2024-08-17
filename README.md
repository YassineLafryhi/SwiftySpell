# SwiftySpell
> A tool for checking spelling in Swift code

![](https://img.shields.io/badge/license-MIT-brown)
![](https://img.shields.io/badge/version-0.9.5-orange)
![](https://img.shields.io/badge/SwiftSyntax-508.0.1-purple)
![](https://img.shields.io/badge/Yams-5.0.6-red)
![](https://img.shields.io/badge/Commander-0.9.1-green)
![](https://img.shields.io/badge/Xcode-15.2-blue)

## Installation
### Using CocoaPods
To install SwiftySpell using CocoaPods, add the following line to your `Podfile`, then run `pod install`:
```ruby
pod 'SwiftySpell'
```

### Manually
To install SwiftySpell manually, you can run the following commands:

```bash
cd ~/Downloads
LATEST_RELEASE=$(curl -s https://api.github.com/repos/YassineLafryhi/SwiftySpell/releases/latest | grep tag_name | cut -d '"' -f 4)
wget "https://github.com/YassineLafryhi/SwiftySpell/releases/download/${LATEST_RELEASE}/SwiftySpell-v${LATEST_RELEASE}.zip"
unzip "SwiftySpell-v${LATEST_RELEASE}.zip"
sudo mkdir -p /usr/local/bin
sudo mv swiftyspell /usr/local/bin/swiftyspell
sudo chmod +x /usr/local/bin/swiftyspell
```

## Configuration

> [!NOTE]
> `SwiftySpell` supports the same languages as the `NSSpellChecker` class from AppKit. To see the list of supported languages, run the following command: `swiftyspell languages`.

Configure SwiftySpell by running `swiftyspell init` command inside the project folder, then edit the generated `.swiftyspell.yml` configuration file.
This is an example of the configuration file:

```yml
# Languages to check
languages:
  - en

# Words to ignore
ignoreList:
  - iOS

# Regular expressions to exclude
excludePatterns:
  - \b[0-9a-fA-F]{6}\b # Color hex codes
  - \bhttps?:\/\/[^\s]+\b # URLs

# Files to exclude
excludeFiles:
  - Constants.swift

# Directories to exclude
excludeDirectories:
  - Pods # Exclude the Pods directory for a CocoaPods project
```

## Usage

### Xcode
Integrate SwiftySpell into your Xcode project to get warnings displayed in the issue navigator.

To do so, select the project in the file navigator, then select the primary app target, and go to Build Phases. Click the + and select "New Run Script Phase". Insert the following script:
> If installed using CocoaPods :

```shell
"${PODS_ROOT}/SwiftySpell/SwiftySpell" check "${SRCROOT}"
```

> If installed manually :

```shell
if which swiftyspell >/dev/null; then
  swiftyspell check "${SRCROOT}"
else
  echo "warning: SwiftySpell is not installed, download it from: https://github.com/YassineLafryhi/SwiftySpell"
fi
```
![](Screenshots/Screenshot1.png)

An example of the warnings displayed in Xcode:

| Warnings on the Editor area      | Warnings on the Issue Navigator  |
|----------------------------------|----------------------------------|
| ![](Screenshots/Screenshot2.png) | ![](Screenshots/Screenshot3.png) |

### Command Line
Run SwiftySpell from the command line by navigating to the directory containing the Swift project you want to check and running the following command:
```shell
swiftyspell check .
```

### As a pre-commit git hook
You can use SwiftySpell as a pre-commit git hook to check spelling before committing your changes. To do so, add the following to the `.git/hooks/pre-commit` file:
```shell
#!/bin/sh
if [ -n "$(swiftyspell check .)" ]; then
  echo "Spelling errors found. Please fix them before committing."
  exit 1
fi
```

## How to build

To build SwiftySpell from source, run the following commands:

```shell
git clone https://github.com/YassineLafryhi/SwiftySpell.git
cd SwiftySpell
xcodebuild -project SwiftySpell.xcodeproj -scheme SwiftySpell -configuration Release build CONFIGURATION_BUILD_DIR=$(pwd)/Build
open Build
# Then you can move Build/SwiftySpell to /usr/local/bin/swiftyspell
```

## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License
[MIT License](https://choosealicense.com/licenses/mit)
