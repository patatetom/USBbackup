#!/usr/bin/bash


# ce module (script) borg est destiné au script USBbackup@.sh
# la restauration d'une sauvegarde peut être réalisée à partir de borg (CLI)
# ou à partir de l'une des nombreuses interfaces graphiques pour borg :
# https://github.com/loomi-labs/arco
# https://github.com/karanhudia/borg-ui
# https://github.com/borgbase/vorta
# !! le dépôt borg (les sauvegardes) n'est pas chiffré !!


target="$backup/borg/$HOSTNAME/$USER"


export BORG_EXIT_CODES=modern
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes


# création du dossier cible et test d'écriture
mkdir -p "$target"
! touch "$target/.test" &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde borg des données personnelles" \
		--app-icon=error \
		"🔴 Impossible d'écrire dans le dossier dédié du média USB." &&
		exit 1
rm "$target/.test"


# initialisation borg
borg init --encryption none "$target"
case $? in
	0|10) ;;
	*)
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde borg des données personnelles" \
		--app-icon=error \
		"🔴 Une erreur est survenue lors de l'initialisation." &&
		exit 1 ;;
esac


# sauvegarde
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde borg des données personnelles" \
	--app-icon=backup \
	"Démarrage de la sauvegarde (1/4)..."
# recherche dans le home de l'utilisateur tous les fichiers de moins de 1Go*
# exclusion de certains dossiers non souhaités (cache, poubelle, etc...)
# puis sauvegarde avec borg à partir des noms de fichiers spécifiés
# la taille limite peut être modifiée au niveau du find (-1Go*)
# d'autres exclusions peuvent être ajoutées au niveau du grep (-e ...)
set -o pipefail
find ~ -type f -size -$((1024*1024*1024))c |
grep -v \
	-e "^$HOME/.cache" \
	-e "^$HOME/.local/share" |
borg create --compression zstd --paths-from-stdin "$target::{now:%Y%m%d%H%M}"
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde borg des données personnelles" \
		--app-icon=error \
		"🔴 Une erreur est survenue lors de la sauvegarde." &&
		exit 1


# purge des sauvegardes (conservation des 5 dernières)
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde borg des données personnelles" \
	--app-icon=backup \
	"Nettoyage de la sauvegarde (2/4)..."
! borg prune --keep-last=5 "$target" &&
	notify-send \
		--urgency=normal \
		--app-name="Sauvegarde borg des données personnelles" \
		--app-icon=error \
		"🟠 Un problème est survenu lors du nettoyage."


# compactage du dépôt (récupération d'espace)
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde borg des données personnelles" \
	--app-icon=backup \
	"Compactage de la sauvegarde (3/4)..."
! borg compact "$target" &&
	notify-send \
		--urgency=normal \
		--app-name="Sauvegarde borg des données personnelles" \
		--app-icon=error \
		"🟠 Un problème est survenu lors du compactage."


# vérification du dépôt
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde borg des données personnelles" \
	--app-icon=backup \
	"Vérification de la sauvegarde (4/4)..."
! borg check "$target" &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde borg des données personnelles" \
		--app-icon=error \
		"🔴 Une erreur est survenue lors de la vérification." &&
		exit 1


# abandon de la variable target (cf. USBbackup@.sh)
unset target
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde borg des données personnelles" \
	--app-icon=success \
	"✅ Sauvegarde borg terminée avec succès."

