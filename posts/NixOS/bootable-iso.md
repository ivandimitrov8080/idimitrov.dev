---
title: NixOS bootable ISO image download
date: 2026-05-01
author: Ivan Dimitrov
description: NixOS bootable ISO image download page for https://github.com/ivandimitrov8080/configuration.nix
---

## Requirements

- USB flash drive of at least 8GB
- Computer with a HDD or SSD to install to
- [Download the boot.iso file](/nix/boot.iso)

## Flash

### Windows

- [Download](https://rufus.ie/en/) Rufus flash utility
- Insert your USB into the computer
- Start Rufus and select the USB as device
- On boot selection select the downloaded boot.iso
- Click start and wait while Rufus is flashing to the USB

### Linux

- Insert your USB into the computer
- Run `sudo dd if=/path/to/boot.iso of=/dev/sdX bs=4M status=progress` (`/dev/sdX` change `X` to what your USB has as name)
- Wait dd to finish
