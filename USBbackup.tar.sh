#!/usr/bin/bash


# this tar module (script) is intended for the USBbackup@.sh script
# backup restoration can be done with the command:
# cat /path/to/USBbackup/{HOSTNAME}/{USER}/USBbackup.tar.zst-* |
# tar -C /tmp/ -xv [...]
# !! tar backups are NOT encrypted !!


target="$backup/tar/$HOSTNAME/$USER"


# create target directory and test write access
mkdir -p "$target"
! touch "$target/.test" &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data tar backup" \
		--app-icon=error \
		"🔴 Cannot write to the dedicated folder on the USB media." &&
		exit 1
rm "$target/.test"


# tar backup
# TODO check target fs to split or not
notify-send \
	--urgency=normal \
	--app-name="Personal data tar backup" \
	--app-icon=backup \
	"Starting backup (1/2)..."
# search the user's home for all files smaller than 1GB*
# and print their names terminated with a null character
# then create a tar archive compressed with zstd from the specified file names
# excluding certain unwanted directories (cache, trash, etc...)
# and finally split the archive into 4GB chunks (FAT32 max)
# the size limit can be changed in the find command (-1GB*)
# additional exclusions can be added to tar (--exclude ...)
set -o pipefail
find ~ -type f -size -$((1024*1024*1024))c -print0 |
tar \
	--exclude "$HOME/.cache" \
	--exclude "$HOME/.local/share" \
	--null -T- --zstd -c |
split -d -a 4 -b 4G - "$target/USBbackup.tar.zst-"
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data tar backup" \
		--app-icon=error \
		"🔴 An error occurred during the backup." &&
		exit 1


# remove possible leftovers from the previous backup
! find "$target" \
	-type f \
	-not -newer "$target/USBbackup.tar.zst-0000" \
	-not -samefile "$target/USBbackup.tar.zst-0000" \
	-delete &&
	notify-send \
		--urgency=normal \
		--app-name="Personal data tar backup" \
		--app-icon=error \
		"🟠 A problem occurred during cleanup."


# verify the backup
notify-send \
	--urgency=normal \
	--app-name="Personal data tar backup" \
	--app-icon=backup \
	"Verifying backup (2/2)..."
set -o pipefail
cat "$target/USBbackup.tar.zst-"* |
tar --zstd -t > /dev/null
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data tar backup" \
		--app-icon=error \
		"🔴 An error occurred during verification." &&
		exit 1


# unset the target variable (see USBbackup@.sh)
unset target
notify-send \
	--urgency=normal \
	--app-name="Personal data tar backup" \
	--app-icon=success \
	"✅ Tar backup completed successfully."

