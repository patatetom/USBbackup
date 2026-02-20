#!/usr/bin/bash


# ce module (script) tar est destiné au script USBbackup@.sh
# la restauration de la sauvegarde peut être réalisée avec la commande :
# cat /path/to/USBbackup/{HOSTNAME}/{USER}/USBbackup.tar.zst-* |
# tar -C /tmp/ -xv [...]
# !! la sauvegarde tar n'est pas chiffrée !!


target="$backup/tar/$HOSTNAME/$USER"


# création du dossier cible et test d'écriture
mkdir -p "$target"
! touch "$target/.test" &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde tar des données personnelles" \
		--app-icon=error \
		"🔴 Impossible d'écrire dans le dossier dédié du média USB." &&
		exit 1
rm "$target/.test"


# sauvegarde tar
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde tar des données personnelles" \
	--app-icon=backup \
	"Démarrage de la sauvegarde (1/2)..."
# recherche dans le home de l'utilisateur tous les fichiers de moins de 1Go*
# et affiche leur nom terminé par le caractère nul
# puis crée une archive tar compressée (zstd) à partir des noms de fichiers spécifiés
# en excluant certains dossiers non souhaités (cache, poubelle, etc...)
# et enfin découpe l'archive en morceaux de 4Go (max. FAT32)
# la taille limite peut être modifiée au niveau du find (-1Go*)
# d'autres exclusions peuvent être ajoutées au niveau du tar (--exclude ...)
set -o pipefail
find ~ -type f -size -$((1024*1024*1024))c -print0 |
tar \
	--exclude "$HOME/.cache" \
	--exclude "$HOME/.local/share" \
	--null -T- --zstd -c |
split -d -a 4 -b 4G - "$target/USBbackup.tar.zst-"
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde tar des données personnelles" \
		--app-icon=error \
		"🔴 Une erreur est survenue lors de la sauvegarde." &&
		exit 1


# suppression des éventuels reliquats de la précédente sauvegarde
! find "$target" \
	-type f \
	-not -newer "$target/USBbackup.tar.zst-0000" \
	-not -samefile "$target/USBbackup.tar.zst-0000" \
	-delete &&
	notify-send \
		--urgency=normal \
		--app-name="Sauvegarde tar des données personnelles" \
		--app-icon=error \
		"🟠 Un problème est survenu lors du nettoyage."


# vérification de la sauvegarde
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde tar des données personnelles" \
	--app-icon=backup \
	"Vérification de la sauvegarde (2/2)..."
set -o pipefail
cat "$target/USBbackup.tar.zst-"* |
tar --zstd -t > /dev/null
(( $? != 0 )) &&
	notify-send \
		--urgency=critical \
		--app-name="Sauvegarde tar des données personnelles" \
		--app-icon=error \
		"🔴 Une erreur est survenue lors de la vérification." &&
		exit 1


# abandon de la variable target (cf. USBbackup@.sh)
unset target
notify-send \
	--urgency=normal \
	--app-name="Sauvegarde tar des données personnelles" \
	--app-icon=success \
	"✅ Sauvegarde tar terminée avec succès."

