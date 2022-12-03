#!/usr/bin/env bash
set -e # exit on error

START_DIR="$(pwd)"
source "$START_DIR/scripts/shared_functions.sh"
setup "$1"

cd chromium/src

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "master" ]] && [[ "$BRANCH" != xarantolus-* ]] || [[ "$BRANCH" == *-base ]]; then
	echo "Branch $BRANCH does not start with xarantolus (or ends with base); are you sure you are on a working branch?"
	exit 1
fi

# Now check out the bromite base branch
git checkout bromite-bromite-base


output "Recreating xarantolus-$BUILD_TYPE branch"
git branch -D "xarantolus-$BUILD_TYPE-base" || true
git checkout -b "xarantolus-$BUILD_TYPE-base"

apply_patches "$START_DIR/patches" "$MY_PATCHES_LIST_FILE" "xarantolus"

git checkout -B "xarantolus-$BUILD_TYPE-changes"
