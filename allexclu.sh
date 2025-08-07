#!/usr/bin/env bash

USB_LABEL="MYUSB"
MOUNT_POINT="/mnt/usbdrive"
SOURCE_DIRS=( "$HOME" "/" )
EXTENSIONS=( "rs" "py" "env" "sh" "toml" "json" "onnx" "txt" "zip" "rar" )

# ✅ Find the correct device path using label
DEVICE_PATH=$(lsblk -lp -o NAME,LABEL | grep -iw "$USB_LABEL" | awk '{print "/dev/" $1}' | head -n 1)

if [ -z "$DEVICE_PATH" ]; then
    exit 1
fi

# ✅ Unmount if mounted
sudo umount "${DEVICE_PATH}"* 2>/dev/null

# ✅ Create mount point if not exists
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# ✅ Mount the USB
sudo mount "$DEVICE_PATH" "$MOUNT_POINT"

# ✅ Copy files with selected extensions excluding system paths
for ext in "${EXTENSIONS[@]}"; do
    for dir in "${SOURCE_DIRS[@]}"; do
        sudo find "$dir" \
            -path "$MOUNT_POINT" -prune -o \
            -path "/proc" -prune -o \
            -path "/sys" -prune -o \
            -path "/dev" -prune -o \
            -path "/boot" -prune -o \
            -path "/nix" -prune -o \
            -type f -iname "*.$ext" -exec sudo cp --parents {} "$MOUNT_POINT" \;
    done
done

# ✅ Sync and unmount safely
sync
sudo umount "$MOUNT_POINT"

# echo "✅ Done. Files copied excluding system paths. USB safely unmounted."
