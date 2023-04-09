#!/usr/bin/env bash

set -e # exit on error
START_DIR="$(pwd)"
source "$START_DIR/scripts/shared_functions.sh"

setup "$1"

generate_out_dir
build_chromium
