---
title: LUKS encrypted drive stopped working on a server
goal: Diagnose faulty LUKS-encrypted drive to figure out what happened and possibly fix it
role:
date: 21 Sep 2023
z: 7
author: Ivan Dimitrov
published: Nov 2023
---

[LUKS](https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup) is an encryption specifications for Linux used to encrypt disk partitions. The
[cryptsetup](https://man.archlinux.org/man/cryptsetup.8.en) utility is usually used for that. After a partition is encrypted it can be opened for reading and writing after
inputting a password or a keyfile.

### Technical details

> cryptsetup is used to conveniently setup dm-crypt managed device-mapper mappings. These include plain dm-crypt volumes and LUKS volumes. The difference is that LUKS uses a
> metadata header and can hence offer more features than plain dm-crypt. On the other hand, the header is visible and vulnerable to damage.

So after a partition is encrypted it has a LUKS header with some encryption metadata and a body. The header tells the program (cryptsetup) how to decrypt the partition. If that
header is damaged in any way then trying to decrypt it using `cryptsetup luksOpen /dev/sdx1` will print `Device /dev/sdx1 is not a valid LUKS device.` if the system is up-to-date.
On the server this happened the system was CentOS 7 with cryptsetup version 2.0.3 (as opposed to 2.6.1) so when I tried to decrypt it didn't prompt for a password and didn't print
anything. After upgrading the version following [this gitlab issue](https://gitlab.com/cryptsetup/cryptsetup/-/issues/783) I got it to print that message so I had something to
google.

> Please test with last released and supported version (currently 2.5.0), we do not have resources to debug old versions, thanks.

A good bit of googling led me to [this thread](https://bbs.archlinux.org/viewtopic.php?id=284768) on the Arch Linux forums. They describe the steps needed to diagnose most LUKS
problems. One thing that was different in this case was the command `sudo dd if=/dev/sdx1 count=20 | hexdump -C` printed only zeroes.

```bash
dd if=/dev/sdx1 count=20 | hexdump -C
00000000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 |................|
*
20+0 records in
20+0 records out
10240 bytes (10 kB, 10 KiB) copied, 0.00229011 s, 4.5 MB/s
```

Testing with a larger block count `count=2050` showed that the first 2030 or so blocks were completely wiped. This meant that the LUKS header and possibly some of the data are
gone. This could still be fixed with a header backup file using `cryptsetup luksHeaderRestore <device> --header-backup-file <file>`.

Unfortunately, there was no header backup file so the only solution was to restore a backup of the entire partition.

### Utilities used

Encrypt a partition

```bash
cryptsetup luksFormat /dev/sdx1
```

Open a LUKS volume and create a decrypted mapping at `/dev/mapper/target`

```bash
cryptsetup luksOpen /dev/sda1 target
```

Close a mapping

```bash
cryptsetup luksClose target
```

Print the hexadecimal representation of a file

```bash
hexdump -C ./file
```

Get the first 20 blocks of data from a partition and pipe them to hexdump to display their hexadecimal representation

```bash
dd if=/dev/sdx1 count=20 | hexdump -C
```
