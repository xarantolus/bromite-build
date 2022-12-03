# bromite-build
This repository contains scripts to build and edit [Bromite](https://github.com/bromite/bromite) from source. Since I couldn't get a normal build to work, the build happens inside a Docker container.

Currently only a build for `arm64` is compiled. To [build for other architectures](https://chromium.googlesource.com/chromium/src/+/master/docs/android_build_instructions.md#figuring-out-target_cpu) one has to adjust the `target_cpu` flag passed to `gn` in the [build config](patches/potassium.gn_args).

This repository also contains my own patches for Bromite, of which there currently aren't many.

There's also a [dev container](https://code.visualstudio.com/docs/devcontainers/containers) configuration for VSCode, which makes it very easy to set up the dev environment.

### Usage
First you should make sure you have a machine that is powerful enough to run this build. I recommend having at least 16GB of RAM and a powerful processor.

Then make sure you have `make` installed. On Ubuntu, you can install it with `sudo apt install make`.

Then you can take a look at the [`Makefile`](Makefile) to see what targets are available. The most commonly used targets while developing are `current` (also available via the `bake` command in the container) and `patch`.
* `bromite`: downloads Chromium and Bromite code, applies the patches and builds Bromite (the `chrome_public_apk` target). Note that the default bromite distribution does not contain branding, so it looks like normal Chromium
* `chromium`: downloads Chromium code and Bromite code and builds Chromium patched with some patches from Bromite (same as the official Bromite Chromium release)
* `current`: Does *not* update the Chromium and Bromite code, but rather just builds what is there. This assumes you want to build Potassium, my own browser variant (it uses the `out/Potassium` directory)
* `patch-bromite`, `patch-chromium`: Downloads & patches the code, but doesn't run the build
* `patch`: Extracts commits you made to the current branch to patch files in the `patches` directory (the branch *must* start with `xarantolus-` and must not end with `-base`; these branches are created by the build script to know where your changes started)
* `container`: Builds the Docker container. Do this if you don't want to use the pre-built container from the GitHub registry or there were changes to the Dockerfile. This container is the base container for the VSCode dev container
* `gc`: Runs `git gc` on the Chromium repository within Docker
* `install`: Assumes you're on Windows and uses `adb` to install a built Bromite APK
* `upgrade`: Updates the chromium checkout to the latest tag specified by Bromite, applies all Bromite patches to the code and applies all patches from this repo to the code. The last step will probably fail, so you'll have to fix the patches manually. See [my notes on this](docs/How-to-upgrade-to-latest-Bromite-version.md) to see how to continue in case of failure
* `shell`: Allows you to run commands inside the Docker container
* `apks`: Copies built APKs from the chromium output directory to an `apks` directory, this is useful for keeping all app versions you have built

