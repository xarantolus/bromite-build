#!/usr/bin/env bash
set -e # exit on error

if [ -z "$START_DIR" ]; then
    START_DIR="$(pwd)"
fi

output() {
    echo "--------------------------------------------------------------------------------"
    echo "$@"
    echo "--------------------------------------------------------------------------------"
}

set_email() {
    git config user.name "xarantolus"
    git config user.email "xarantolus@protonmail.com"
}

install_depot_tools() {
    pushd "$START_DIR" > /dev/null

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

    popd > /dev/null
}

parse_build_arg() {
    export BUILD_TYPE="${1:-potassium}"

    if [ "$BUILD_TYPE" = "chromium" ]; then
        export MY_PATCHES_LIST_FILE=""
        export BROMITE_PATCHES_LIST_FILE="$START_DIR/bromite/build/chromium_patches_list.txt"
        export ARGS_GN_FILE="$START_DIR/bromite/build/chromium.gn_args"
        export OUT_DIR="out/Chromium"
    elif [ "$BUILD_TYPE" = "bromite" ]; then
        export MY_PATCHES_LIST_FILE=""
        export BROMITE_PATCHES_LIST_FILE="$START_DIR/bromite/build/bromite_patches_list.txt"
        export ARGS_GN_FILE="$START_DIR/bromite/build/bromite.gn_args"
        export OUT_DIR="out/Bromite"
    elif [ "$BUILD_TYPE" = "potassium" ]; then
        export MY_PATCHES_LIST_FILE="$START_DIR/patches/potassium_patches_list.txt"
        export BROMITE_PATCHES_LIST_FILE="$START_DIR/bromite/build/bromite_patches_list.txt"
        export ARGS_GN_FILE="$START_DIR/patches/potassium.gn_args"
        export OUT_DIR="out/Potassium"
    else
        output "Unknown build type: $BUILD_TYPE"
        exit 1
    fi
}

pull_bromite() {
    pushd "$START_DIR" > /dev/null

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
    # One can also set BROMITE_TAG before running the script; this is done for the upgrade logic
    if [ -z "$BROMITE_TAG" ]; then
        BROMITE_TAG="$(cat "$START_DIR/patches/BROMITE_COMMIT")"
    fi
    cd bromite && git checkout "$BROMITE_TAG" && cd ..

    popd > /dev/null
}

pull_chromium() {
    pushd "$START_DIR" > /dev/null

    if [ -d "chromium" ]; then
        cd chromium
        # Basically reset to origin/master in case anything was changed, e.g. applied patches
        output "Cleaning Chromium repository"
        cd src
        git checkout -f -B master origin/master
        # also make sure any failed patches are removed
        git am --abort > /dev/null 2>&1 || true

        cd ..

        output "Updating local Chromium checkout for Android"
        # fallback to sync command to get latest changes. If that one doesn't work, then we're out of luck
        gclient sync --nohooks --reset --revision "src@$BROMITE_RELEASE_VERSION"
    else
        mkdir chromium && cd chromium

        # Don't fetch history in CI
        if [ "$CI" == "true" ]; then
            output "Fetching Chromium for Android (no history)"
            fetch --nohooks --no-history android
        else
            output "Fetching Chromium for Android"
            fetch --nohooks android
        fi
    fi

    output "Done fetching code"

    popd > /dev/null
}

install_chromium_dependencies() {
    pushd "$START_DIR/chromium/src" > /dev/null

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

    popd > /dev/null
}

apply_patches() {
    # First argument is the directory containing the patches
    # second argument is path to the file listing all patch basenames
    # third argument is a description of the patches

    pushd "$START_DIR/chromium/src" > /dev/null

    output "Applying $3 patches from $2"

    # first make sure any failed patches are removed
    git am --abort > /dev/null 2>&1 || true

    while read -r patch; do
        if [ -z "$patch" ]; then
            continue
        fi

        output "Applying $3 patch $patch"
        git am < "$1/$patch"
    done < "$2"

    output "Finished applying patches from $2"

    popd > /dev/null
}

generate_out_dir() {
    pushd "$START_DIR/chromium/src" > /dev/null

    output "Generating $OUT_DIR directory"

    ARGS_CONTENTS="$(cat "$ARGS_GN_FILE")"
    ADDITIONAL_ARGS="target_cpu=\"arm64\""
    ARGS_CONTENTS="$ARGS_CONTENTS $ADDITIONAL_ARGS"

    output "BUILD ARGS:"
    echo "$ARGS_CONTENTS"
    output "END BUILD ARGS"

    gn gen --args="$ARGS_CONTENTS" "$OUT_DIR"

    popd > /dev/null
}

build_chromium() {
    pushd "$START_DIR/chromium/src" > /dev/null

    output "Building $BUILD_TYPE, starting at $(date)"
    ninja -C "$OUT_DIR" chrome_public_apk

    output "Done building $BUILD_TYPE, finished at $(date)"

    APK_FILE=$(find "$OUT_DIR" -name "*.apk")

    output "Built APK file: $APK_FILE"

    ls -lsh "$APK_FILE"

    output "Finished building $BUILD_TYPE"

    popd > /dev/null
}

setup() {
    parse_build_arg "$1"

    set_email

    install_depot_tools

    pull_bromite
}
