#!/usr/bin/bash

# /run/media/$USER (or may be /media/$USER) directory does not exist before
# first USB insertion : the hack is to mount/unmount an tiny floppy
# this hack is performed once at user login
floppy=$( mktemp )
zstd -d > "$floppy" < \
<(
base64 -d <<++++
KLUv/WQACd0FAAQJ6zyQTVNXSU40LjEAAgEBAAIQAAUA8AEAEgACACnvvq3eVVNCYmFja3VwICBG
QVQxMiAgIABVqvD///8PAAhBcgBlAGEAZABtAA8Ac2UALgB0AHgAdP////9SRUFETUUgIFRYVCAA
K8ylWFxYXAAAAgAnaHR0cHM6Ly9naXRodWIuY29tL3BhdGF0ZXRvbS8KDQAFKDjuLnUDITR3BBVI
wYcrNoJWIJCpYJdj6B8gVHAPVB4vUAMY5AEWnpYM
++++
)
# udisksctl returns something like "Mapped file /tmp/tmp.drYrUsTIyf as /dev/loop0."
loop=$(
	udisksctl loop-setup -r -f "$floppy" |
	grep -E -o '/dev/loop[0-9]+'
)
# udisksctl returns something like "Mounted /dev/loop0 at /run/media/user/..."
[ -n "$loop" ] &&
	udisk=$(
		udisksctl mount -o ro -b "$loop" |
		grep -E -o "/[^ ]+/$USER"
	)
[ -n "$udisk" ] &&
	udisksctl unmount -b "$loop"
[ -n "$loop" ] &&
	udisksctl loop-delete -b "$loop"

# exit if the user directory is missing
[ -z "$udisk" ] &&
	echo "unable to find mount point for user USB media" >&2 &&
		exit 1

# subdirectory intended for backups
# TODO emojis in the folder name...
repository=USBbackup

# monitor the user directory
inotifywait -m "$udisk" |
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
