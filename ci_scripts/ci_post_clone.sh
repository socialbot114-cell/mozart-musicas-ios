#!/bin/sh
set -eu

REPOSITORY_PATH="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"

if ! command -v xcodegen >/dev/null 2>&1; then
    brew install xcodegen
fi

cd "$REPOSITORY_PATH/ios"
xcodegen generate --spec project.yml
