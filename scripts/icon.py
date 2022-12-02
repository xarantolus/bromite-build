#!/usr/bin/env python3
import os

# This script generates the icon for the app from a defined icon file

DEFAULT_ICON="assets/icon.png"
LAYERED="assets/layered_app_icon.png"
BACKGROUND_ICON="assets/background_icon.png"
PRODUCT_IMG="assets/product_logo_name.png"

OUTPUT_DIRS=[
    "chromium/src/chrome/android/java/res_chromium_base",
    "chromium/src/chrome/android/java/res_chromium",
]

def icon_to_use(filename):
	filename = os.path.basename(filename).lower()
	if "background" in filename:
		return BACKGROUND_ICON
	elif "layered" in filename:
		return LAYERED
	elif "logo_name" in filename:
		return PRODUCT_IMG
	else:
		return DEFAULT_ICON

for dir in OUTPUT_DIRS:
	for root, subdirs, files in os.walk(dir):
		for file in files:
			# Basically replace all files that have a chromium logo in them with the matching file
			if file.endswith(".png"):
				file_path = os.path.join(root, file)

				cmd = "ffmpeg -i " + file_path + " 2>&1 | grep -oE '([0-9]+x[0-9]+)'"

				image_size = os.popen(cmd).read().strip()

				# now use ffmpeg to resize INPUT_FILE to image_size and overwrite file_path

				cmd = "ffmpeg -i " + icon_to_use(file_path) + " -pix_fmt rgba -s " + image_size + " -y " + file_path
				os.system(cmd)

				print("Resized " + file_path + " to " + image_size)


