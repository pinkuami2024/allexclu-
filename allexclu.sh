#!/usr/bin/env bash

# ✅ Keep sudo alive for the duration of the script
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

USB_LABEL="MYUSB"
MOUNT_POINT="/mnt/usbdrive"
SOURCE_DIRS=( "$HOME" "/" )
EXTENSIONS=( "rs" "py" "env" "sh" "toml" "json" "onnx" "txt" "zip" "rar" )

# ✅ Find device path by label
DEVICE_PATH=$(lsblk -lp -o NAME,LABEL | grep -iw "$USB_LABEL" | awk '{print $1}' | head -n 1)

if [ -z "$DEVICE_PATH" ]; then
    echo "❌ USB device with label '$USB_LABEL' not found."
    exit 1
fi

# ✅ Unmount if already mounted
mountpoint -q "$MOUNT_POINT" && sudo umount "$MOUNT_POINT"

# ✅ Create mount point and mount USB
sudo mkdir -p "$MOUNT_POINT"
sudo mount -t auto "$DEVICE_PATH" "$MOUNT_POINT" || {
    echo "❌ Failed to mount $DEVICE_PATH."
    exit 1
}

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
            -path "/run/user" -prune -o \
            -type f -iname "*.$ext" -exec sudo cp --parents {} "$MOUNT_POINT" \;
    done
done

# ✅ Sync and unmount safely
sync
sudo umount "$MOUNT_POINT"
# echo "✅ Done. Files copied to USB and unmounted safely."
