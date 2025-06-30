#!/bin/bash

# Check if Flutter is installed
if command -v flutter &> /dev/null; then
    # Flutter is in PATH, use it directly
    flutter "$@"
elif [ -d "$HOME/flutter/bin" ]; then
    # Try common Flutter installation directory
    $HOME/flutter/bin/flutter "$@"
elif [ -d "/usr/local/flutter/bin" ]; then
    # Try another common installation directory
    /usr/local/flutter/bin/flutter "$@"
else
    echo "Flutter SDK not found. Please install Flutter or provide the correct path."
    echo "Visit https://docs.flutter.dev/get-started/install for installation instructions."
    exit 1
fi