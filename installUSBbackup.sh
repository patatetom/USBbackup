#!/usr/bin/bash

# message
echo
echo "This script will install USBbackup into your environment if all required conditions are met."
read -sp "Press [Enter] to continue or [Ctrl]-[C] to cancel"$'\n'
echo

# systemd
[[ ! "$( ps -p 1 -o comm= 2> /dev/null )" == "systemd" ]] &&
	echo "🔴 systemd is not the system's INIT" >&2 &&
		exit 1
echo "✅ systemd"

# udisk2
! type -a udisksctl &> /dev/null &&
	echo "🟠 udisks2 is missing and must be installed" >&2 &&
		exit 2
! systemctl is-active udisks2 &> /dev/null &&
	echo "🟡 udisks2 is present but not operational" >&2 &&
		exit 3
echo "✅ udisks2"

# zstd
! type -a zstd &> /dev/null &&
	echo "🟠 zstd is missing and must be installed" >&2 &&
		exit 2
echo "✅ zstd"

# base64 (coreutils)
! type -a base64 &> /dev/null &&
	echo "🟠 base64 (coreutils) is missing and must be installed" >&2 &&
		exit 2
echo "✅ base64"

# inotifywait (inotify-tools)
! type -a inotifywait &> /dev/null &&
	echo "🟠 inotifywait (inotify-tools) is missing and must be installed" >&2 &&
		exit 2
echo "✅ inotifywait"

# notify-send (libnotify-bin)
! type -a notify-send &> /dev/null &&
	echo "🟠 notify-send (libnotify-bin) is missing and must be installed" >&2 &&
		exit 2
echo "✅ notify-send"

((m++))
# tar
type -a tar &> /dev/null &&
	echo "✅ tar" && ((m++)) ||
	echo "🟡 tar is missing and must be installed if used" >&2

# borg (borgbackup)
type -a borg &> /dev/null &&
	echo "✅ borg" && ((m++)) ||
	echo "🟡 borg (borgbackup) is missing and must be installed if used" >&2

# rsync
type -a rsync &> /dev/null &&
	echo "✅ rsync" && ((m++)) ||
	echo "🟡 rsync is missing and must be installed if used" >&2

(( $m == 0 )) &&
	echo "🟠 none of the three required tools are present" >&2 &&
		exit 2

# message
echo
echo "Proceed with installing USBbackup into your environment?"
read -sp "Press [Enter] to continue or [Ctrl]-[C] to cancel"$'\n'
echo

echo "Copying files..."
mkdir -p -v ~/.config/systemd/user/
cp -v ./USBbackup*.service ~/.config/systemd/user/
chmod -x ~/.config/systemd/user/USBbackup*.service
mkdir -p -v ~/.local/bin/
cp -v ./USBbackup*.sh ~/.local/bin/
chmod -x ~/.local/bin/USBbackup*.sh
echo

echo "Installing and starting the service..."
systemctl --user --verbose daemon-reload
systemctl --user --verbose enable USBbackup
systemctl --user --verbose start --now USBbackup
echo
