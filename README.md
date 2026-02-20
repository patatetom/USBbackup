# USBbackup : plug ⏬ & backup 🔁
**Simple backup solution on USB media**

USBbackup is a Linux systemd backup solution entirely in user space :
once properly installed, any USB media with a folder named `/USBbackup/` at the root of one of its partitions inserted into a USB port becomes a backup media and automatically triggers a backup when inserted.



## Installation

- Download the USBbackup ZIP archive using the `<> Code v` button
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
✅ udisks2
✅ zstd
✅ base64
✅ inotifywait
✅ notify-send
✅ tar
🟡 borg (borgbackup) is missing and must be installed if used
🟡 rsync is missing and must be installed if used

Proceed with installing USBbackup into your environment ?
Press [Enter] to continue or [Ctrl]-[C] to cancel

Copying files...
'./USBbackup.service' -> '/home/me/.config/systemd/user/USBbackup.service'
'./USBbackup@.service' -> '/home/me/.config/systemd/user/USBbackup@.service'
'./USBbackup.borg.sh' -> '/home/me/.local/bin/USBbackup.borg.sh'
'./USBbackup.rsync.sh' -> '/home/me/.local/bin/USBbackup.rsync.sh'
'./USBbackup.sh' -> '/home/me/.local/bin/USBbackup.sh'
'./USBbackup@.sh' -> '/home/me/.local/bin/USBbackup@.sh'
'./USBbackup.tar.sh' -> '/home/me/.local/bin/USBbackup.tar.sh'

Installing and starting the service...
```

> `tar` should be available on your system : if not, install it.<br/>
> `borg` or `rsync` will probably need to be installed if you want to use it.



## Configuration

If you prefer to use borg or rsync, you must modify the USBbackup configuration.

- Edit the file `/home/me/.local/bin/USBbackup@.sh`
- Choose the module to use by uncommenting the corresponding line

USBbackup with `borg` :
```bash
# uncomment to use tar as backup solution
#source ~/.local/bin/USBbackup.tar.sh
# uncomment to use borg as backup solution
source ~/.local/bin/USBbackup.borg.sh
# uncomment to use rsync as backup solution
#source ~/.local/bin/USBbackup.rsync.sh
```

USBbackup with `rsync` :
```bash
# uncomment to use tar as backup solution
#source ~/.local/bin/USBbackup.tar.sh
# uncomment to use borg as backup solution
#source ~/.local/bin/USBbackup.borg.sh
# uncomment to use rsync as backup solution
source ~/.local/bin/USBbackup.rsync.sh
```

> Using multiple modules is entirely possible but will necessarily require more time and more space on your USB media.
