#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="/home/and/Pictures"

rsync -rltv --info=progress2 "$SOURCE/" "$SCRIPT_DIR/"

echo
echo "Files copied successfully to:"
echo "$SCRIPT_DIR"
