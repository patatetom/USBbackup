#!/usr/bin/bash

# subdirectory intended for backups
repository=USBbackup

# monitoring mounts/unmounts with findmnt
# grep filter is based on the mount points used by udisks2
LANG= findmnt --poll --noheadings --canonicalize --output ACTION,TARGET |
	grep -E --line-buffered " (/run)?/media/$USER/" |
		while read -r event
		do
			mount="/${event#*/}"
			if grep -q '^umount' <<< "$event"
			then
				# rebuild the identifier to stop the dedicated service
				id=$( base64 -w0 <<< "$mount/$repository" )
				systemctl --user stop --now "USBbackup@${id%%=*}.service"
			else
				backup="$mount/$repository"
				# check for presence of the USBbackup subdirectory
				if [ -d "$backup" ]
				then
					# backup identifier used by the dedicated service
					# remove unnecessary base64 padding
					id=$( base64 -w0 <<< "$backup" )
					systemctl --user start "USBbackup@${id%%=*}.service"
				fi
			fi
		done
