# VM Images

[![AI Slop Inside](https://sladge.net/badge.svg)](https://sladge.net)

# Before you try it yourself

Look inside `/secrets` directory. You have to create secret `.nix` files 
corresponding to `configuration.nix` of image you want to build. 
For example, if you want to build `preinstalled-docker`, you have to make copy of
`/secrets/user.sample.nix` with name `/secrets/user.nix`, and adjust:
- For user's password you want to run `mkpasswd -m yescrypt`, and insert the 
  result as `hashedPassword` value
- For user's authorizedKeys you typically want to copy value from your `~/id_rsa.pub`

There is also `/secrets/cryptroot.key` file needed to encrypt image contents and
vm drive, but it is generated automatically.

## ⚠️ **Important** security note
Images here have encrypted drives, but in my configuration protects only against 
trivial attacks by default, because `/secrets/cryptroot.key` is copied to **unencrypted** 
partition inside the image, so it is available to anyone who has access to image or
vm itself. You may want to change this, if so
- Change `image.nix` of vm:
  Remove sections `boot.initrd.secrets` (so secrets not included in image) and
  `boot.initrd.luks.devices."cryptroot"` (so password asked during boot)
- Enable `ttyS0`
- Write `/secrets/cryptroot.key` file manually before build, so you can provide 
  the key manually by entering it during boot.
  (by default it is generated as random sequence of bytes)
- Disable `_key` prerequisite, so key will not be regenerated during build.

After doing all this, your image will be built without embedded drive encryption
key inside. However, you still will need to provide it during boot (typically through 
your hosting provider's VM console), so cryptographically speaking - nothing 
changed at all. 
So it didn't seem worth it to me, and skipping manual password entering during 
each boot is meaningful usability improvement in comparison to _not have_ more 
cryptographically secure image. But have to note my suspicion, that hosting 
providers are less likely to perform attack on your VM by hijacking your 
console interactions, than to just look into your image. It's your choice here.

## One more security note

All secrets used in build process end up in `/nix/store`.
After building an image, you should run garbage collection to 
remove unreachable store paths:

```bash
sudo nix-collect-garbage -d
```

## Source code layout

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
