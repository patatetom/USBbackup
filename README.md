# USBbackup : ⏬ plug && backup 🔁
**Easy user backup solution on USB storage device**

USBbackup is a Linux `systemd` backup solution entirely in user space :
once installed, any USB storage device containing a folder named “/USBbackup/” at the root of one of its partitions becomes a backup medium and automatically triggers a backup when inserted into a USB port.



> _If partition of your USB storage device selected for USBbackup must remain compatible with other operating systems, choose ExFAT as file system._
> _Otherwise, choose a journaled file system supported by your distribution._



## 📎 Installation

- [Download](https://github.com/patatetom/USBbackup/archive/refs/heads/main.zip) the USBbackup ZIP archive
- Extract the contents of the archive
- Navigate to the `USBbackup_main/` folder created by the extraction
- _Check the code_
- Open a terminal there
- Run the command `bash installUSBbackup.sh`

```terminal
$ [/path/to/extracted/USBbackup-main] bash installUSBbackup.sh 

This script will install USBbackup into your environment if all required conditions are met.
Press [Enter] to continue or [Ctrl]-[C] to cancel

✅ systemd
✅ zstd
✅ base64
✅ notify-send
🟡 rsync is missing and must be installed if used
✅ tar
🟡 borg (borgbackup) is missing and must be installed if used

Proceed with installing USBbackup into your environment ?
Press [Enter] to continue or [Ctrl]-[C] to cancel

Copying files...
Installing and starting the service...
```

> `borg` or `rsync` will probably need to be installed if you want to use it.



## 🧩 Missing tools

Here are the commands that should allow to install the missing tools on the three main Linux distributions and their derivatives.
The command must be preceded by `sudo` in order to temporarily elevate privileges.

|                 | Debian                    | Fedora                    | OpenSuse                       |
|-----------------|---------------------------|---------------------------|--------------------------------|
| **notify-send** | apt install libnotify-bin | dnf install libnotify     | zypper install libnotify-tools |
| **borg**        | apt install borgbackup    | dnf install borgbackup    | zypper install borgbackup      |
| **rsync**       | apt install rsync         | dnf install rsync         | zypper install rsync           |

> `notify-send` must be version 0.7.11 or higher to take advantage of the `action` option, which allows to cancel the backup during startup.



## ⚙️ Configuration

USBbackup use `tar` by default, but if you prefer to use `borg` or `rsync`, you must modify the USBbackup configuration.

- Edit the file `~/.local/bin/USBbackup@.sh` (`$HOME/.local/bin/USBbackup@.sh`)
- Choose the module to use by uncommenting the corresponding line

USBbackup with `borg` :
```bash
#source ~/.local/bin/USBbackup.tar.sh
source ~/.local/bin/USBbackup.borg.sh
#source ~/.local/bin/USBbackup.rsync.sh
```

USBbackup with `rsync` :
```bash
#source ~/.local/bin/USBbackup.tar.sh
#source ~/.local/bin/USBbackup.borg.sh
source ~/.local/bin/USBbackup.rsync.sh
```

> `borg` will be preferred to `tar` if it is already installed on the system.
> Using multiple modules is possible but will necessarily require more time and more space on your USB storage device.



## 👧🧑 Multiple users

USBbackup must be installed for each user of the workstation who wishes to back up their personal folder.
The backup is stored in `…/USBbackup/{Type}/{HostName}/{User}/`.

> **Provided `tar`, `borg`, and `rsync` backups are not encrypted or protected.**



## 🧰 `tar` backup

`tar` backup, which is default backup, is the simplest to implement since everything needed to perform it should be natively present in Linux.
Its main drawback is that it systematically backs up all data (no delta).
`tar` backup is perfect for a small or medium volume of data to be backed up.

> Files larger than 1 GB and `~/.cache/` and `~/.local/share/` folders are excluded from backup.<br/>
> Given FAT32, archive (tarball) is split into 4GB chunks.



## 📦 `borg` backup

`borg` is an excellent backup software (developed in Python).
Unlike `tar`, `borg` uses deduplication, which avoids retransferring all data to be backed up : only changes since last backup are backed up.
While first (full) backup may take some time, subsequent (deduplicate) backups are usually significantly faster.

> Files larger than 1 GB and `~/.cache/` and `~/.local/share/` folders are excluded from backup.<br/>
> `borg` is configured to keep the last 5 backups.



## 💼 `rsync` backup

`rsync`, originally intended for remote synchronization, is also an excellent backup software.
Like `borg`, once first backup (full) is completed, `rsync` only backs up differences that have appeared.
Unlike `tar` and `borg`, `rsync` does not use compressed container(s) to store files that can be naturally retrieved from USB storage device.
**Difference between file systems (HOME vs. USB) can lead to inconsistencies.**

> Files larger than 1 GB and `~/.cache/` and `~/.local/share/` folders are excluded from backup.



## ⚗️ `etc…` backup

Using scripts provided as inspiration, you can easily set up your own backup solution based on tool of your choice.
You can also modify script provided for your chosen solution to reconfigure backup (exclusions, max file size to be considered, encryption, etc…).
