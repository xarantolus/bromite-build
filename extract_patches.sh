# Basically create patch files from everything that was added on top of Bromite or (Bromite-)Chromium
# This requires that the build.sh script has been run for Bromite or (Bromite-)Chromium

START_DIR="$(pwd)"

# Collect bromite version info
cd bromite
BROMITE_COMMIT="$(git rev-parse HEAD)"
BROMITE_LATEST_TAG="$(git describe --tags --abbrev=0)"
cd ..

# Now collect chromium info
cd chromium/src
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Basically the workflow is like this:
# 1. Run make patch-chromium
# 2. Go to chromium/src and check out a new branch named xarantolus-somefeature (based on xarantolus-bromite-base)
# 3. Make changes
# 4. Run this script to generate patches

if [[ "$BRANCH" != xarantolus-* ]] || [[ "$BRANCH" == *-base ]]; then
	echo "Branch $BRANCH does not start with xarantolus (or ends with base); are you sure you applied the patches and checked out a new branch?"
	exit 1
fi

# Now we can remove all previous patches
PATCHES="$(find "$START_DIR"/patches -name "*.patch")"
rm -f $PATCHES

git format-patch --no-numbered -o "$START_DIR/patches" "bromite-potassium-base..$BRANCH"

echo "$BROMITE_LATEST_TAG" > "$START_DIR/patches/BROMITE_VERSION"
echo "$BROMITE_COMMIT" > "$START_DIR/patches/BROMITE_COMMIT"

cd "$START_DIR/patches"
ls *.patch > "$START_DIR/patches/potassium_patches_list.txt"
