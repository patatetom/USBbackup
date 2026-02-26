#!/usr/bin/bash

set -e -u

# message
echo
echo "This script will install USBbackup into your environment if all required conditions are met."
read -r -s -p "Press [Enter] to continue or [Ctrl]-[C] to cancel"$'\n'
echo

die() { echo "$1"$'\n' >&2; exit ${2:-1}; }

# systemd
init="$( ps --pid 1 --format comm= 2>/dev/null )"
[[ "$init" != "systemd" ]] &&
	die "🔴 systemd is not the system's INIT"
echo "✅ systemd"

# zstd
! type -a zstd &>/dev/null &&
	die "🟠 zstd is missing and must be installed" 2
echo "✅ zstd"

# base64 (coreutils)
! type -a base64 &>/dev/null &&
	die "🟠 base64 (coreutils) is missing and must be installed" 2
echo "✅ base64"

# notify-send (libnotify-bin)
! type -a notify-send &>/dev/null &&
	die "🟠 notify-send (libnotify-bin) is missing and must be installed" 2
# check notify-send version against 0.7.11
IFS='.' read -r x y z <<< $(
	notify-send --version |
	grep --extended-regexp --only-matching '[0-9]+\.[0-9]+\.[0-9]+'
)
version=$(( 10#${x:-0} * 10000 + 10#${y:-0} * 100 + 10#${z:-0} ))
(( version < 711 )) &&
	echo "🟡 notify-send (<0.7.11 2022)" ||
	echo "✅ notify-send"

flag=""

# tar
type -a tar &>/dev/null &&
	echo "✅ tar" &&
		flag="x" ||
	echo "🟡 tar is missing and must be installed if used"

# borg (borgbackup)
type -a borg &>/dev/null &&
	echo "✅ borg" &&
		flag="x" ||
	echo "🟡 borg (borgbackup) is missing and must be installed if used"

# rsync
type -a rsync &>/dev/null &&
	echo "✅ rsync" &&
		flag="x" ||
	echo "🟡 rsync is missing and must be installed if used"

[[ -z "${flag}" ]] &&
	die "🟠 none of the three required tools are present" 2

# message
echo
echo "Proceed with installing USBbackup into your environment?"
read -r -s -p "Press [Enter] to continue or [Ctrl]-[C] to cancel"$'\n'
echo

# install files
echo "Copying files..."
mkdir --parents --verbose ~/.config/systemd/user/
cp --verbose ./USBbackup*.service ~/.config/systemd/user/
chmod -x ~/.config/systemd/user/USBbackup*.service
mkdir --parents --verbose ~/.local/bin/
cp --verbose ./USBbackup*.sh ~/.local/bin/
chmod -x ~/.local/bin/USBbackup*.sh
echo

# TODO set default backup solution with flag...

# remove `action` option if notify-send < 0.7.11
(( version < 711 )) &&
sed --in-place '/^[[:space:]]*--action="/d' ~/.local/bin/USBbackup@.sh

# install user service
echo "Installing and starting the service..."
systemctl --user daemon-reload
systemctl --user enable USBbackup
systemctl --user start --now USBbackup
echo

