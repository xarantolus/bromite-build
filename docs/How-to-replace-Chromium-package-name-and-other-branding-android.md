# How to replace the Chromium package name and other branding for Android?
This document is a tutorial on how to replace the Chromium package name and other branding.
Since I couldn't find a guide for Android (only for Windows etc.), I'm writing one. I'm not entirely sure if this is the recommended approach, but it is an approach that works.

Prerequisites:
* Have a working Chromium for Android build environment


### Replace the package name
The Android package name is defined in `chromium/src/chrome/android/BUILD.gn`. In this file you can change the `_default_package` variable to the package name that should be used for the Android build.

### Replace the display name
The name displayed in the launcher can be changed by editing `chromium/src/chrome/android/java/res_chromium_base/values/channel_constants.xml`. Just replace the occurrences of `Chromium` with the desired name. Note that instead of `res_chromium_base` you might have to edit files another directory, depending on your build configuration.

### Replace the app icon
To replace the app icon, you basically have to replace all PNG files in both the `chromium/src/chrome/android/java/res_chromium_base` and `chromium/src/chrome/android/java/res_chromium` directories. This can be done using the `icon.py` script from this repository, you just have to replace the referenced files in the top-level `assets` directory with your own files, then run the script again.
