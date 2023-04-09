#!/usr/bin/env bash
set -e # exit on error

# create temporary directory
TEMP_DIR="$(mktemp -d)"
trap "rm -rf $TEMP_DIR" EXIT

pushd "$TEMP_DIR"

git clone --depth 1 https://chromium.googlesource.com/chromium/src/build

# Comment out the line that installs snapcraft - otherwise its installation fails in Docker and blocks the build forever
sed -e '/ snapcraft\"/ s/^#*/    echo \"Skipping snapcraft\" # /' -i build/install-build-deps.sh

# Install build dependencies
build/install-build-deps.sh --no-prompt --arm --android

popd
