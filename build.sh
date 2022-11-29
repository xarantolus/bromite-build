#!/usr/bin/env bash
# Script to download, create and manage a Chromium checkout for Bromite development
#
# Build chromium:
#     ./build.sh chromium
# Build Bromite:
#     ./build.sh bromite
# Create patch branch for chromium:
#     ./build.sh chromium patch
# Create patch branch for Bromite:
#     ./build.sh bromite patch

set -e # exit on error

output() {
    echo "--------------------------------------------------------------------------------"
    echo "$@"
    echo "--------------------------------------------------------------------------------"
}

git config user.name "xarantolus"
git config user.email "xarantolus@protonmail.com"

START_DIR="$(pwd)"

output "Working in $START_DIR"

output "Pulling Bromite repo"
if [ -d "bromite" ]; then
    cd bromite
    git checkout -f -B master origin/master
    git pull
    cd ..
else
    git clone https://github.com/bromite/bromite.git
fi

# Check out the commit our patches are based upon
cd bromite && git checkout "$(cat "$START_DIR/patches/BROMITE_COMMIT")" && cd ..

# first argument is the build type, defaults to chromium
BUILD_TYPE="${1:-chromium}"
if [ "$BUILD_TYPE" = "chromium" ]; then
    BROMITE_PATCHES_LIST_FILE="$START_DIR/bromite/build/chromium_patches_list.txt"
    ARGS_GN_FILE="$START_DIR/bromite/build/chromium.gn_args"
    OUT_DIR="out/Chromium"
elif [ "$BUILD_TYPE" = "bromite" ]; then
    BROMITE_PATCHES_LIST_FILE="$START_DIR/bromite/build/bromite_patches_list.txt"
    ARGS_GN_FILE="$START_DIR/bromite/build/bromite.gn_args"
    OUT_DIR="out/Bromite"
else
    output "Unknown build type: $BUILD_TYPE"
    exit 1
fi

BROMITE_RELEASE_VERSION="$(cat "$START_DIR/bromite/build/RELEASE")"

if [ "$2" = "patch" ]; then
    output "Patch type: $BUILD_TYPE, applying from $BROMITE_RELEASE_VERSION with $BROMITE_PATCHES_LIST_FILE"
else
    output "Build type: $BUILD_TYPE, building from $BROMITE_RELEASE_VERSION with $ARGS_GN_FILE + $BROMITE_PATCHES_LIST_FILE in $OUT_DIR"
fi


# Install depot_tools
output "Checking depot_tools..."
if [ -d "depot_tools" ]; then
    cd depot_tools
    git reset --hard HEAD # in case anything was saved here
    git pull origin "$CURRENT_BRANCH"
    cd ..
else
    # Install depot_tools
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

# make them available for further build steps
export PATH="$PATH:$(pwd)/depot_tools"

output "All tools are installed"


if [ -d "chromium" ]; then
  cd chromium
  # Basically reset to origin/master in case anything was changed, e.g. applied patches
  output "Cleaning Chromium repository"
  cd src && git checkout -f -B master origin/master && cd ..

  output "Updating local Chromium checkout for Android"
  # fallback to sync command to get latest changes. If that one doesn't work, then we're out of luck
  gclient sync --nohooks --reset --revision "src@$BROMITE_RELEASE_VERSION"
else
    output "Fetching Chromium for Android"
    mkdir chromium && cd chromium
    fetch --nohooks android
fi

echo "Currently in $(pwd)"
cd src

output "Done fetching code"

output "Resetting Chromium source code to Bromite base version"
git checkout -f "$BROMITE_RELEASE_VERSION"

output "Recreating bromite-$BUILD_TYPE-base branch"
git branch -D "bromite-$BUILD_TYPE-base" || true
git checkout -b "bromite-$BUILD_TYPE-base"

if [ ! "$2" = "patch" ]; then
    output "Installing build dependencies"

    # Comment out the line that installs snapcraft - otherwise its installation fails in Docker and blocks the build forever
    sed -e '/ snapcraft\"/ s/^#*/    echo \"Skipping snapcraft\" # /' -i build/install-build-deps.sh

    # Install build dependencies
    build/install-build-deps.sh --no-prompt --arm
    build/install-build-deps-android.sh --no-prompt

    # Reset our uncommented line above
    git checkout -- build/install-build-deps.sh

    output "Running hooks"
    gclient runhooks
fi

output "Applying patches"

# first make sure any failed patches are removed
git am --abort > /dev/null 2>&1 || true

while read -r patch; do
    if [ -z "$patch" ]; then
        continue
    fi
    output "Applying bromite patch $patch"
    git am < "$START_DIR/bromite/build/patches/$patch"
done < "$BROMITE_PATCHES_LIST_FILE"

# Now apply my own patches (on their own branch)
output "Recreating xarantolus-$BUILD_TYPE branch"
git branch -D "xarantolus-$BUILD_TYPE-base" || true
git checkout -b "xarantolus-$BUILD_TYPE-base"

output "Applying patches from xarantolus"
MY_PATCHES_LIST_FILE="$START_DIR/patches/bromite_patch_list.txt"

while read -r patch; do
    if [ -z "$patch" ]; then
        continue
    fi
    output "Applying my own patch $patch"
    git am < "$START_DIR/patches/$patch"
done < "$MY_PATCHES_LIST_FILE"

output "Finished applying patches"

if [ "$2" = "patch" ]; then
    exit 0
fi

# Only generate out dir if it doesn't exist
if [ ! -d "$OUT_DIR" ]; then
    ARGS_CONTENTS="$(cat "$ARGS_GN_FILE")"
    ADDITIONAL_ARGS="target_cpu=\"arm64\""
    ARGS_CONTENTS="$ARGS_CONTENTS $ADDITIONAL_ARGS"

    output "BUILD ARGS:"
    echo "$ARGS_CONTENTS"
    output "END BUILD ARGS"

    gn gen --args="$ARGS_CONTENTS" "$OUT_DIR"
fi

output "Building $BUILD_TYPE, starting at $(date)"
ninja -C "$OUT_DIR" chrome_public_apk

output "Done building $BUILD_TYPE, finished at $(date)"
find "$OUT_DIR" -name "*.apk"
