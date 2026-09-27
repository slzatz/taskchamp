#!/bin/sh
# Xcode pre-build phase: lint on every build (warnings only, never fails the build).

if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if which swiftlint > /dev/null; then
    swiftlint taskchamp/Sources
    swiftlint taskchampWidget/Sources
    swiftlint taskchampShared/Sources
    swiftlint taskchampShareExtension/Sources
else
    echo "warning: SwiftLint not installed, run: brew install swiftlint"
fi
