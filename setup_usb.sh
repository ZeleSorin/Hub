#!/usr/bin/env bash
set -euo pipefail

# Step 1: Show block devices so the user can confirm the USB device
echo "=== Block devices ==="
lsblk
echo ""
read -rp "Enter the USB device to mount (e.g. /dev/sda1): " USB_DEVICE

# Step 2: Mount the confirmed device to /mnt/usb
mkdir -p /mnt/usb
mount "$USB_DEVICE" /mnt/usb

# Step 3: Create the PostgreSQL data directory
mkdir -p /mnt/usb/postgresql

# Step 4: Set ownership to postgres:postgres (falls back to uid/gid 999 if user not yet created)
if id postgres &>/dev/null; then
    chown postgres:postgres /mnt/usb/postgresql
else
    chown 999:999 /mnt/usb/postgresql
fi

# Step 5: Restrict permissions — only owner may read, write, or enter
chmod 700 /mnt/usb/postgresql

echo "Success: $USB_DEVICE mounted at /mnt/usb and /mnt/usb/postgresql is ready."
