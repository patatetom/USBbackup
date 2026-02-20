#!/usr/bin/bash


# basic check
[ -z "$1" ] &&
	echo "$0 requires a parameter" > /dev/stderr &&
		exit 1
backup=$( base64 -d <<< "$1")
[ ! -d "$backup" ] &&
	echo "directory $backup does not exist" > /dev/stderr &&
		exit 1


# notification with user choice
(( $(
	notify-send \
		--urgency=critical \
		--app-name="Personal data backup" \
		--app-icon=backup \
		--action="I understand" \
		--action="Cancel backup" \
		"⚠️ THE USB MEDIA MUST NOT BE UNPLUGGED during the backup operation."
) == 1 )) && exit 0


# the variable target must be unset by the selected module
target=to-be-unset-by-selected-module


################################################################################
# uncomment to use tar as backup solution
#source ~/.local/bin/USBbackup.tar.sh


# uncomment to use borg as backup solution
#source ~/.local/bin/USBbackup.borg.sh


# uncomment to use rsync as backup solution
#source ~/.local/bin/USBbackup.rsync.sh
################################################################################


# the last used module must unset the target variable
[ -n "$target" ] &&
	notify-send \
		--urgency=critical \
		--app-name="Personal data backup" \
		--app-icon=backup \
		"🔴 No backup module is defined." &&
		exit 1

exit 0
