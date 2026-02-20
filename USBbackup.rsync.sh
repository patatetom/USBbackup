#!/usr/bin/bash


# ce module (script) rsync est destiné au script USBbackup@.sh
# !! la sauvegarde tar n'est pas chiffrée !!


target="$backup/rsync/$HOSTNAME/$USER"


# création du dossier cible et test d'écriture
mkdir -p "$target"
! touch "$target/.test" &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde rsync des données personnelles" \
		--app-icon=error \
		"🔴 Impossible d'écrire dans le dossier dédié du média USB." &&
		exit 1
rm "$target/.test"


# sauvegarde rsync
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde rsync des données personnelles" \
	--app-icon=backup \
	"Démarrage de la sauvegarde..."
# synchronise depuis le home de l'utilisateur tous les fichiers de moins de 1Go
# en excluant certains dossiers non souhaités (cache, poubelle, etc...)
# d'autres exclusions peuvent être ajoutées au niveau du rsync (--exclude ...)
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
		--app-name="Sauvegarde tar des données personnelles" \
		--app-icon=error \
		"🔴 Une erreur est survenue lors de la sauvegarde." &&
		exit 1


# abandon de la variable target (cf. USBbackup@.sh)
unset target
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde rsync des données personnelles" \
	--app-icon=success \
	"✅ Sauvegarde rsync terminée avec succès."

