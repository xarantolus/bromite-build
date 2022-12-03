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
START_DIR="$(pwd)"
source "$START_DIR/scripts/shared_functions.sh"

setup "$1"

BROMITE_RELEASE_VERSION="$(cat "$START_DIR/bromite/build/RELEASE")"

if [ "$2" = "patch" ]; then
    output "Patch type: $BUILD_TYPE, applying from $BROMITE_RELEASE_VERSION with $BROMITE_PATCHES_LIST_FILE"
else
    output "Build type: $BUILD_TYPE, building from $BROMITE_RELEASE_VERSION with $ARGS_GN_FILE + $BROMITE_PATCHES_LIST_FILE in $OUT_DIR"
fi


pull_chromium

cd chromium/src

echo "Currently in $(pwd)"

output "Resetting Chromium source code to Bromite base version"
git checkout -f "$BROMITE_RELEASE_VERSION"

output "Recreating bromite-$BUILD_TYPE-base branch"
git branch -D "bromite-$BUILD_TYPE-base" || true
git checkout -b "bromite-$BUILD_TYPE-base"

install_chromium_dependencies

# Apply bromite patches
apply_patches "$START_DIR/bromite/build/patches" "$BROMITE_PATCHES_LIST_FILE" "bromite"

if [ -n "$MY_PATCHES_LIST_FILE" ]; then
    # Now apply my own patches (on their own branch)
    output "Recreating xarantolus-$BUILD_TYPE branch"
    git branch -D "xarantolus-$BUILD_TYPE-base" || true
    git checkout -b "xarantolus-$BUILD_TYPE-base"

    # Apply my patches
    apply_patches "$START_DIR/patches" "$MY_PATCHES_LIST_FILE" "xarantolus"
fi

if [ "$2" = "patch" ]; then
    exit 0
fi

generate_out_dir

build_chromium

