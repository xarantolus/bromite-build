set -e # exit on error

output() {
    echo "--------------------------------------------------------------------------------"
    echo "$@"
    echo "--------------------------------------------------------------------------------"
}

START_DIR="$(pwd)"

output "Working in $START_DIR"

# first argument is the build type, defaults to chromium
BUILD_TYPE="${1:-chromium}"
if [ "$BUILD_TYPE" = "chromium" ]; then
    PATCHES_LIST_FILE="$START_DIR/bromite/build/chromium_patches_list.txt"
    ARGS_GN_FILE="$START_DIR/bromite/build/chromium.gn_args"
    OUT_DIR="out/Chromium"
elif [ "$BUILD_TYPE" = "bromite" ]; then
    PATCHES_LIST_FILE="$START_DIR/bromite/build/bromite_patches_list.txt"
    ARGS_GN_FILE="$START_DIR/bromite/build/bromite.gn_args"
    OUT_DIR="out/Bromite"
else
    output "Unknown build type: $BUILD_TYPE"
    exit 1
fi

BROMITE_RELEASE_COMMIT="$(cat "$START_DIR/bromite/build/RELEASE_COMMIT")"

output "Build type: $BUILD_TYPE, building from $BROMITE_RELEASE_COMMIT with $ARGS_GN_FILE+$PATCHES_LIST_FILE in $OUT_DIR"

output "Pulling Bromite repo"
if [ -d "bromite" ]; then
    cd bromite
    git pull
    cd ..
else
    git clone https://github.com/bromite/bromite.git
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

output "Downloading Chromium source code for Android"

if [ -d "chromium" ]; then
  cd chromium
  # Basically reset to origin/master in case anything was changed, e.g. applied patches
  cd src && git checkout -f -B master origin/master && cd ..
  # fallback to sync command to get latest changes. If that one doesn't work, then we're out of luck
  # The -D flag removes any unused/unnecessary parts of the repository that are no longer needed
  gclient sync -D
else
    mkdir chromium && cd chromium
    fetch --nohooks android
fi

cd src

output "Done fetching code"

output "Resetting Chromium source code to Bromite base version"
git checkout -f "$BROMITE_RELEASE_COMMIT"

output "Applying patches"
while read -r patch; do
    if [ -z "$patch" ]; then
        continue
    fi
    output "Applying patch $patch"
    git apply "$START_DIR/bromite/build/patches/$patch"
done < "$PATCHES_LIST_FILE"

output "Installing build dependencies"

# Comment out the line that installs snapcraft - otherwise its installation fails in Docker and blocks the build forever
sed -e '/ snapcraft\"/ s/^#*/    echo \"Skipping snapcraft\" # /' -i build/install-build-deps.sh

# Install build dependencies
build/install-build-deps.sh --no-prompt --arm || true
build/install-build-deps-android.sh --no-prompt || true

# Reset our uncommented line above
git checkout -- build/install-build-deps.sh

output "Running hooks"
gclient runhooks

ARGS_CONTENTS="$(cat "$ARGS_GN_FILE")"
ADDITIONAL_ARGS="target_cpu=\"arm64\""
ARGS_CONTENTS="$ARGS_CONTENTS $ADDITIONAL_ARGS"

output "BUILD ARGS:"
echo "$ARGS_CONTENTS"
output "END BUILD ARGS"

gn gen --args="$ARGS_CONTENTS" "$OUT_DIR"

output "Building $BUILD_TYPE"
ninja -C "$OUT_DIR" chrome_public_apk

output "Done building $BUILD_TYPE"
find "$OUT_DIR" -name "*.apk"
