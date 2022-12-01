#!/usr/bin/env python3
import os

# This script generates the icon for the app from a defined icon file

INPUT_FILE="assets/icon.png"
OUTPUT_DIR="chromium/src/chrome/android/java/res_chromium_base"

for root, subdirs, files in os.walk(OUTPUT_DIR):
	for file in files:

		# png file and not background files
		if file.endswith(".png") and not "background" in file:
			file_path = os.path.join(root, file)

			cmd = "ffmpeg -i " + file_path + " 2>&1 | grep -oE '([0-9]+x[0-9]+)'"

			image_size = os.popen(cmd).read().strip()

			# now use ffmpeg to resize INPUT_FILE to image_size and overwrite file_path

			cmd = "ffmpeg -i " + INPUT_FILE + " -pix_fmt rgba -s " + image_size + " -y " + file_path
			os.system(cmd)

			print("Resized " + file_path + " to " + image_size)


