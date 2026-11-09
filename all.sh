#!/bin/bash
set -e

# Directory where this script lives (backups are created here,
# regardless of where the script is run from, including /)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="/home/and"

# Source folder -> destination folder (inside SCRIPT_DIR)
declare -A FOLDERS=(
    ["Documents"]="Documents"
    ["Music"]="Music"
    ["Pictures"]="Pictures"
    ["Videos"]="Videos"
)

# Execution order
ORDER=(Documents Music Pictures Videos)

for name in "${ORDER[@]}"; do
    SOURCE="$USER_HOME/$name"
    DEST="$SCRIPT_DIR/${FOLDERS[$name]}"

    if [ ! -d "$SOURCE" ]; then
        echo "WARNING: source not found, skipping: $SOURCE"
        continue
    fi

    echo
    echo "=== Copying $name ==="
    mkdir -p "$DEST"
    rsync -rltv --info=progress2 "$SOURCE/" "$DEST/"

    echo
    echo "$name copied successfully to:"
    echo "$DEST"
done

echo
echo "Backup complete! Folders created in:"
echo "$SCRIPT_DIR"
