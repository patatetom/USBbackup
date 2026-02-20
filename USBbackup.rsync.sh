#!/usr/bin/bash


# this rsync module (script) is intended for the USBbackup@.sh script
# !! rsync backups are NOT encrypted !!


target="$backup/rsync/$HOSTNAME/$USER"


# create target directory and test write access
mkdir -p "$target"
! touch "$target/.test" &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data rsync backup" \
		--app-icon=error \
		"🔴 Cannot write to the dedicated folder on the USB media." &&
		exit 1
rm "$target/.test"


# rsync backup
notify-send \
	--urgency=normal \
	--app-name="Personal data rsync backup" \
	--app-icon=backup \
	"Starting backup..."
# synchronize from the user's home all files smaller than 1GB
# excluding certain unwanted directories (cache, trash, etc...)
# the size limit can be changed in the rsync command (--max-size=)
# additional exclusions can be added to rsync (--exclude=)
rsync \
	--archive \
	--update \
	--delete \
	--max-size=1G \
	--prune-empty-dirs \
	--modify-window=1 \
	--exclude=".cache/" \
	--exclude=".local/share/" \
	"$HOME/" "$target/"
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data rsync backup" \
		--app-icon=error \
		"🔴 An error occurred during the backup." &&
		exit 1


# unset the target variable (see USBbackup@.sh)
unset target
notify-send \
	--urgency=normal \
	--app-name="Personal data rsync backup" \
	--app-icon=success \
	"✅ Rsync backup completed successfully."

