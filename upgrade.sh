#!/usr/bin/env bash
set -e # exit on error

# Upgrades the chromium checkout with my own changes to the latest version of Bromite.

START_DIR="$(pwd)"
source "$START_DIR/scripts/shared_functions.sh"

# Update bromite repository
cd bromite
git checkout -f -B master origin/master
git pull
BROMITE_LATEST_TAG="$(git describe --tags --abbrev=0)"
git checkout "tags/$BROMITE_LATEST_TAG"
BROMITE_COMMIT="$(git rev-parse HEAD)"
cd ..

cd chromium/src

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "master" ]] && [[ "$BRANCH" != xarantolus-* ]] || [[ "$BRANCH" == *-base ]]; then
	echo "Branch $BRANCH does not start with xarantolus (or ends with base); are you sure you are on a working branch?"
	exit 1
fi

# Fetch Chromium changes, resetting to the latest Bromite version and then applying all patches patches
cd "$START_DIR"
BROMITE_TAG="$BROMITE_LATEST_TAG" ./build.sh potassium patch
