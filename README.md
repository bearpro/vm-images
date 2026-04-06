# VM Images

[![AI Slop Inside](https://sladge.net/badge.svg)](https://sladge.net)

## Soruce code layout

This repository keeps image-building concerns split into three layers.

## Configuration Layers

- `configuration.nix`: user-facing operating system configuration. This file should describe the system that a user expects to get after boot: users, SSH, Docker, packages, locale, hostname, and similar system behavior.
- `disco.nix`: disk layout for the image. This file should describe how the target disk is partitioned and formatted: partition table, filesystems, LUKS, mount points, and image size.
- `*-image.nix`: deployment-target image settings. These files should adapt the base system to a specific environment such as Proxmox or Yandex Cloud: image builder selection, bootloader/image format settings, guest profiles, platform-specific kernel modules, and any deployment-specific glue.

## Design Rule

When changing the build:

- Put user and service behavior into `configuration.nix`.
- Put storage topology into `disco.nix`.
- Put environment-specific boot and image-generation details into `*-image.nix`.

The goal is to keep the same system definition reusable across different deployment targets while changing only the disk model and target-specific image settings when needed.

