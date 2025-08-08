#!/usr/bin/env bash

USB_LABEL="MYUSB"
MOUNT_POINT="/mnt/usbdrive"
SOURCE_DIRS=( "$HOME" "/" )
EXTENSIONS=( "rs" "py" "env" "sh" "toml" "json" "onnx" "txt" "zip" "rar" )

DEVICE_PATH=$(lsblk -lp -o NAME,LABEL | grep -iw "$USB_LABEL" | awk '{print $1}' | head -n 1)

if [ -z "$DEVICE_PATH" ]; then
    echo "❌ Device with label '$USB_LABEL' not found."
    exit 1
fi

# Unmount if already mounted
mountpoint -q "$MOUNT_POINT" && sudo umount "$MOUNT_POINT"

# Mount the USB
sudo mkdir -p "$MOUNT_POINT"
sudo mount -t auto "$DEVICE_PATH" "$MOUNT_POINT" || {
    echo "❌ Failed to mount $DEVICE_PATH."
    exit 1
}

# Copy files
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

sync
sudo umount "$MOUNT_POINT"
echo "✅ Done. Files copied to USB and unmounted safely."
