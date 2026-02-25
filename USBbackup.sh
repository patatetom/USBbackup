#!/usr/bin/bash

# get udisks mount location from daemon code
udisks="$(
	strings -d "$(
		ps ax |
		grep -o '/.*/udisksd$'
	)" |
	grep -E -o '(/run)?/media/%s'
)"
[ -z "$udisks" ] &&
	echo "enable to get udisks mount location" >&2 &&
		exit 1
udisks="${udisks%/%s}"
[ ! -d "$udisks" ] &&
	echo "udisks mount location does not exist" >&2 &&
		exit 1

# monitors creation of user folder if necessary (match file also)
# /run/media/$USER (and may be /media/$USER) directory does not exist before
# first USB insertion
[ -d "$udisks/$USER" ] ||
	inotifywait -e create --include "/$USER\$" "$udisks"

# subdirectory intended for backups
repository=USBbackup

# monitor the user directory
inotifywait -m "$udisks/$USER" |
	while read -r path event item
	do
		if [[ "$event" == "CREATE,ISDIR" ]]
		# USB media inserted : new directory created in followed folder
		then
			# normalize the mount point
			mount=$( readlink --canonicalize-missing "$path/$item" )
			# wait for the mount
			# 10s max, in 2s slices
			for sleep in 1 2 3 4 5
			do
				grep -q "$mount" /proc/mounts && continue || sleep 2
			done
			# normalize the backup path
			backup=$( readlink --canonicalize-missing "$mount/$repository" )
			# check for presence of the USBbackup subdirectory
			if [ -d "$backup" ]
			then
				# backup identifier used by the dedicated service
				# remove unnecessary base64 padding
				id=$( base64 <<< "$backup" )
				systemctl --user start "USBbackup@${id%%=*}.service"
			fi
		elif [[ "$event" == "DELETE,ISDIR" ]]
		# logical or physical removal of a USB media
		# a directory is deleted in /run/media/$USER
		then
			# rebuild the identifier to stop the dedicated service
			mount=$( readlink --canonicalize-missing "$path/$file" )
			backup=$( readlink --canonicalize-missing "$mount/$repository" )
			id=$( base64 <<< "$backup" )
			systemctl --user stop --now "USBbackup@${id%%=*}.service"
		fi
	done
