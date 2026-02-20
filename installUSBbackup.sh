#!/usr/bin/bash

# message
echo
echo "ce script va installer USBbackup dans votre environnement si toutes les conditions requises sont présentes."
read -sp "appuyer sur [Entrer] pour continuer ou [Ctrl]-[C] pour annuler"$'\n'
echo

# systemd
[[ ! "$( ps -p 1 -o comm= 2> /dev/null )" == "systemd" ]] &&
	echo "🔴 systemd n'est pas l'INIT du système" > /dev/stderr &&
		exit 1
echo "✅ systemd"

# udisk2
! type -a udisksctl &> /dev/null &&
	echo "🟠 udisk2 est absent et doit être installé" > /dev/stderr &&
		exit 2
! systemctl is-active udisks2 &> /dev/null &&
	echo "🟡 udisk2 est présent mais n'est pas opérationnel" > /dev/stderr &&
		exit 3
echo "✅ udisk2"

# zstd
! type -a zstd &> /dev/null &&
	echo "🟠 zstd est absent et doit être installé" > /dev/stderr &&
		exit 2
echo "✅ zstd"

# base64 (coreutils)
! type -a base64 &> /dev/null &&
	echo "🟠 base64 (coreutils) est absent et doit être installé" > /dev/stderr &&
		exit 2
echo "✅ base64"

# inotifywait (inotify-tools)
! type -a inotifywait &> /dev/null &&
	echo "🟠 inotifywait (inotify-tools) est absent et doit être installé" > /dev/stderr &&
		exit 2
echo "✅ inotifywait"

# notify-send (libnotify-bin)
! type -a inotifywait &> /dev/null &&
	echo "🟠 notify-send (libnotify-bin) est absent et doit être installé" > /dev/stderr &&
		exit 2
echo "✅ notify-send"

((m++))
# tar
type -a tar &> /dev/null &&
	echo "✅ tar" && ((m++)) ||
	echo "🟡 tar est absent et doit être installé si utilisé" > /dev/stderr

# borg (borgbackup)
type -a borg &> /dev/null &&
	echo "✅ borg" && ((m++)) ||
	echo "🟡 borg (borgbackup) est absent et doit être installé si utilisé" > /dev/stderr

# rsync
type -a rsync &> /dev/null &&
	echo "✅ rsync" && ((m++)) ||
	echo "🟡 rsync est absent et doit être installé si utilisé" > /dev/stderr

(( $m == 0 )) &&
	echo "🟠 aucun des trois outils nécessaires n'est présent" > /dev/stderr &&
		exit 2

# message
echo
echo "procéder à l'installation de USBbackup dans votre environnement ?"
read -sp "appuyer sur [Entrer] pour continuer ou [Ctrl]-[C] pour annuler"$'\n'
echo

echo "copie des fichiers..."
mkdir -p -v ~/.config/systemd/user/
cp -v ./USBbackup*.service ~/.config/systemd/user/
chmod -x ~/.config/systemd/user/USBbackup*.service
mkdir -p -v ~/.local/bin/
cp -v ./USBbackup*.sh ~/.local/bin/
chmod -x ~/.local/bin/USBbackup*.sh
echo

echo "installation et démarrage du service..."
systemctl --user --verbose daemon-reload
systemctl --user --verbose enable USBbackup
systemctl --user --verbose start --now USBbackup
echo

