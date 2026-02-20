#!/usr/bin/bash

# le dossier /run/media/$USER n'existe pas avant l'insertion du premier média USB
# la boucle while [ ! -d "/run/media/$USER" ] loupe la création du sous-dossier
# le hack consiste à monter/démonter une pseudo disquette vide de 90Kb
# ce hack est réalisé à l'ouverture de session de l'utilisateur
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

# sortie si absence du dossier utilisateur
# échec de l'étape udisk précédente
[ ! -d "/run/media/$USER" ] &&
	echo "" > /dev/stderr

# sous-dossier destiné aux sauvegardes
# TODO émoticones dans le nom du dossier...
repository=USBbackup

# surveillance du dossier utilisateur
# création d'un sous-dossier à chaque insertion d'un média USB
inotifywait -m "/run/media/$USER" |
	while read -r path event item
	do
		if [[ "$event" == "CREATE,ISDIR" ]]
		# insertion d'un média USB
		# création d'un nouveau dossier dans /run/media/$USER
		then
			# normalisation du point de montage
			mount=$( readlink --canonicalize-missing "$path/$item" )
			# attente du montage
			# 10s max. par tranche de 2s
			for sleep in 1 2 3 4 5
			do
				grep -q "$mount" /proc/mounts && continue || sleep 2
			done
			# normalisation du chemin de sauvergarde
			backup=$( readlink --canonicalize-missing "$mount/$repository" )
			# vérification de la présence du sous-dossier USBbackup
			if [ -d "$backup" ]
			then
				# identitifant de sauvegarde utilisé par le service dédié
				# soustraction du padding base64 inutile
				id=$( base64 <<< "$backup" )
				systemctl --user start "USBbackup@${id%%=*}.service"
			fi
		elif [[ "$event" == "DELETE,ISDIR" ]]
		# retrait (logique ou physique) d'un média USB
		# suppression d'un dossier dans /run/media/$USER
		then
			# reconstitution de l'identifiant pour arrêt du service dédié
			mount=$( readlink --canonicalize-missing "$path/$file" )
			backup=$( readlink --canonicalize-missing "$mount/$repository" )
			id=$( base64 <<< "$backup" )
			systemctl --user stop --now "USBbackup@${id%%=*}.service"
		fi
	done

