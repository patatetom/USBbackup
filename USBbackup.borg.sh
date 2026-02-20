#!/usr/bin/bash


# this borg module (script) is intended for the USBbackup@.sh script
# a backup can be restored using borg (CLI)
# or using one of the many GUI frontends for borg:
# https://github.com/loomi-labs/arco
# https://github.com/karanhudia/borg-ui
# https://github.com/borgbase/vorta
# !! the borg repository (the backups) is NOT encrypted !!


target="$backup/borg/$HOSTNAME/$USER"


export BORG_EXIT_CODES=modern
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes


# create target directory and test write access
mkdir -p "$target"
! touch "$target/.test" &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data borg backup" \
		--app-icon=error \
		"🔴 Cannot write to the dedicated folder on the USB media." &&
		exit 1
rm "$target/.test"


# borg initialization
borg init --encryption none "$target"
case $? in
	0|10) ;;
	*)
	notify-send \
		--urgency=critical \
		--app-name="Personal data borg backup" \
		--app-icon=error \
		"🔴 An error occurred during initialization." &&
		exit 1 ;;
esac


# backup
notify-send \
	--urgency=normal \
	--app-name="Personal data borg backup" \
	--app-icon=backup \
	"Starting backup (1/4)..."
# search the user's home for all files smaller than 1GB*
# exclude certain unwanted directories (cache, trash, etc...)
# then back up with borg from the specified file list
# the size limit can be changed in the find command (-1GB*)
# additional exclusions can be added in the grep (-e ...)
set -o pipefail
find ~ -type f -size -$((1024*1024*1024))c |
grep -v \
	-e "^$HOME/.cache" \
	-e "^$HOME/.local/share" |
borg create --compression zstd --paths-from-stdin "$target::{now:%Y%m%d%H%M}"
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data borg backup" \
		--app-icon=error \
		"🔴 An error occurred during the backup." &&
		exit 1


# prune old backups (keep the last 5)
notify-send \
	--urgency=normal \
	--app-name="Personal data borg backup" \
	--app-icon=backup \
	"Cleaning backups (2/4)..."
! borg prune --keep-last=5 "$target" &&
	notify-send \
		--urgency=normal \
		--app-name="Personal data borg backup" \
		--app-icon=error \
		"🟠 A problem occurred during cleanup."


# compact the repository (reclaim space)
notify-send \
	--urgency=normal \
	--app-name="Personal data borg backup" \
	--app-icon=backup \
	"Compacting backups (3/4)..."
! borg compact "$target" &&
	notify-send \
		--urgency=normal \
		--app-name="Personal data borg backup" \
		--app-icon=error \
		"🟠 A problem occurred during compacting."


# verify the repository
notify-send \
	--urgency=normal \
	--app-name="Personal data borg backup" \
	--app-icon=backup \
	"Verifying backup (4/4)..."
! borg check "$target" &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data borg backup" \
		--app-icon=error \
		"🔴 An error occurred during verification." &&
		exit 1


# unset the target variable (see USBbackup@.sh)
unset target
notify-send \
	--urgency=normal \
	--app-name="Personal data borg backup" \
	--app-icon=success \
	"✅ Borg backup completed successfully."

