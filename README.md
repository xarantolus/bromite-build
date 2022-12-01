# bromite-build
This repository contains scripts to build [Bromite](https://github.com/bromite/bromite) from source. Since I couldn't get a normal build to work, the build happens inside a Docker container.

Note that currently only a build for `arm64` is compiled.

This repository also contains my own patches for Bromite, of which there currently aren't many. I'm also working on a few scripts to make creating patches etc. easier, but my current workflow isn't very good.

### Usage
First you should make sure you have a machine that is powerful enough to run this build. I recommend having at least 16GB of RAM and a powerful processor.

Then make sure you have `make` installed. On Ubuntu, you can install it with `sudo apt install make`.

Then you can take a look at the [`Makefile`](Makefile) to see what targets are available.
* `bromite` (default): downloads Chromium and Bromite code, applies the patches and builds Bromite (the `chrome_public_apk` target)
* `chromium`: downloads Chromium code and Bromite code and builds Chromium patched with some patches from Bromite (same as the official Bromite Chromium release)
* `current`: Does *not* update the Chromium and Bromite code, but rather just builds what is there. This assumes you want to build Bromite (it uses the `out/Bromite` directory)
* `patch-bromite`, `patch-chromium`: Downloads & patches the code, but doesn't run the build
* `patch`: Extracts commits you made to certain branches to patch files in the `patches` directory
* `container`: Builds the Docker container; this is done automatically before other targets that need it
* `gc`: Runs `git gc` on the Chromium repository
* `install`: Assumes you're on Windows and uses `adb` to install a built Bromite APK
* `shell`: Allows you to run commands inside the Docker container

So basically this is all for trying some stuff out and see how it goes :)
