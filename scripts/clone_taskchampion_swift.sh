#!/bin/bash
# Clones the Rust bridge (task-champion-swift) into the repo root, where
# Tuist/Package.swift and build_taskchampion_swift.sh expect it.
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
cd "$SCRIPT_DIR/.."

if [ -d task-champion-swift ]; then
    echo "task-champion-swift already present, not cloning."
    exit 0
fi

git clone https://github.com/marriagav/task-champion-swift.git
