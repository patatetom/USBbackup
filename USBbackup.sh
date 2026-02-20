#!/usr/bin/bash

# the /run/media/$USER directory does not exist before the first USB insertion
# the while [ ! -d "/run/media/$USER" ] loop misses creation of the subdirectory
# the hack is to mount/unmount a 90Kb empty pseudo-floppy
# this hack is performed at user login
if [ ! -d "/run/media/$USER" ]
then
	floppy=$( mktemp )
	zstd -d > "$floppy" < <(
		base64 -d <<-++++
			KLUv/QRY3QMAtAXrPJBta2ZzLmZhdAACBAEAAgACsAD4AQAQAAIAgAApVjn/pVhGQVQxMiAgIA4f
			vlt8rCLAdAtWtA67BwDNEF7r8DLkzRbNGev+AFWq+P//AFhYCAAAqalQXFBcCQDoXyAHfAyyAivY
			rctF9A8QKsgHavEnUA9AzgucgADLHA
			++++
	) 
	if [ ! -d "/run/media/$USER" ]
	then
		udisksctl loop-setup -rf "$floppy" &&
			sleep 2 &&
				umount "$floppy"
	fi
	rm "$floppy"
fi

# exit if the user directory is missing
# previous udisks step failed
[ ! -d "/run/media/$USER" ] &&
	echo "" > /dev/stderr

# subdirectory intended for backups
# TODO emojis in the folder name...
repository=USBbackup

# monitor the user directory
inotifywait -m "/run/media/$USER" |
	while read -r path event item
	do
		if [[ "$event" == "CREATE,ISDIR" ]]
		# USB media inserted
		# a new directory is created in /run/media/$USER
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
