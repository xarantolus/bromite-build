set -e # exit on error

output() {
    echo "--------------------------------------------------------------------------------"
    echo "$@"
    echo "--------------------------------------------------------------------------------"
}

START_DIR="$(pwd)"

echo "Working in $START_DIR"

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

output "Downloading chromium for Android"


if [ -d "chromium" ]; then
#   git rebase-update
  cd chromium
  # fallback to sync command to get latest changes. If that one doesn't work, then we're out of luck
  # The -D flag removes any unused/unnecessary parts of the repository that are no longer needed
  gclient sync -D || (output "OK, running \"gclient sync\" also failed.\nYou should probably remove both the chromium/ and depot_tools/ directory and start over." && exit 1)
else
    mkdir chromium && cd chromium
    fetch --nohooks android || failed=1 && output "\"fetch\" failing doesn't matter.\nUsing \"gclient sync\" to download updates, repo likely has already been downloaded"
fi

cd src

# output "Pulling..."
# git pull

output "Done fetching code"

output "Installing build dependencies"

# Comment out the line that installs snapcraft - otherwise its installation fails in Docker and blocks the build forever
sed -e '/ snapcraft\"/ s/^#*/    echo \"Skipping snapcraft\" # /' -i build/install-build-deps.sh

build/install-build-deps.sh --no-prompt --arm || true
build/install-build-deps-android.sh --no-prompt || true

# Reset our uncommented line
git checkout -- build/install-build-deps.sh

output "Running hooks"

gclient runhooks

# first argument is the build type, default to chromium
BUILD_TYPE="${1:-chromium}"

if [ "$BUILD_TYPE" = "chromium" ]; then
    output "Building normal Chromium APK"
    gn gen --args="target_os=\"android\" target_cpu=\"arm64\"" out/Chromium

    output "Building"
    autoninja -C out/Chromium chrome_public_apk
elif [ "$BUILD_TYPE" = "chrome" ]; then
    echo "TODO"
else
    output "Unknown build type: $BUILD_TYPE"
    exit 1
fi

