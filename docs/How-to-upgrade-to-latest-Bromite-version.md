# How to update to the latest Bromite version
To upgrade the current checkout, just run `make upgrade`. But make sure all your changes have been saved in patch files using `make patch` before that!

The upgrade script will set up everything. It might fail at applying patches, in which case you have to resolve conflicts manually.

A patch failing to apply will look like this:
```
Applying: Package and application name
error: patch failed: chrome/android/BUILD.gn:42
error: chrome/android/BUILD.gn: patch does not apply
error: patch failed: chrome/browser/ui/android/strings/translations/android_chrome_strings_de.xtb:100
error: chrome/browser/ui/android/strings/translations/android_chrome_strings_de.xtb: patch does not apply
Patch failed at 0001 Package and application name
hint: Use 'git am --show-current-patch' to see the failed patch
When you have resolved this problem, run "git am --continue".
If you prefer to skip this patch, run "git am --skip" instead.
To restore the original branch and stop patching, run "git am --abort".
make: *** [Makefile:38: upgrade] Error 128
```

You can run `git am --reject` to create `.rej` files with the conflicts. You can then resolve them manually (by editing the file with the content that should have been applied from the `rej` file), then `git add` your changes and run `git am --resolved` to commit. Note that you should only run this when *all* conflicts have been resolved, otherwise you'll create a commit with only some of the changes. Also make sure not to commit `.rej` files.
