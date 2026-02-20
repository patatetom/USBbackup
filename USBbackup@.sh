#!/usr/bin/bash


# vérification de base
[ -z "$1" ] &&
	echo "$1 nécessite un paramètre" > /dev/stderr &&
		exit 1
backup=$( base64 -d <<< "$1")
[ ! -d "$backup" ] &&
	echo "le dossier $backup est inexistant" > /dev/stderr &&
		exit 1


# notification avec choix utilisateur
(( $(
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde des données personnelles" \
		--app-icon=backup \
		--action="J'ai compris" \
		--action="Annuler" \
		"⚠️ LE MÉDIA USB NE DOIT PAS ÊTRE DÉBRANCHÉ durant l'opération de sauvegarde."
) == 1 )) && exit 0


# la variable target doit être abandonnée par le module utilisé
target=to-be-unset-by-selected-module


################################################################################
# décommenter pour utiliser tar comme solution de sauvegarde
source ~/.local/bin/USBbackup.tar.sh


# décommenter pour utiliser borg comme solution de sauvegarde
#source ~/.local/bin/USBbackup.borg.sh


# décommenter pour utiliser rsync comme solution de sauvegarde
#source ~/.local/bin/USBbackup.rsync.sh
################################################################################


# le dernier module utilisé doit abandonner la variable target
[ -n "$target" ] &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde des données personnelles" \
		--app-icon=backup \
		"🔴 Aucun module de sauvegarde défini." &&
		exit 1

exit 0
