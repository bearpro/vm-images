# remnanode/image.nix
let
  cryptrootKey = builtins.path {
    path = ../secrets/cryptroot.key;
    name = "cryptroot.key";
  };
  diskoSrc = builtins.fetchTarball {
    url = "https://github.com/nix-community/disko/archive/5ad85c82cc52264f4beddc934ba57f3789f28347.tar.gz";
    sha256 = "035nyq47jvhxf2d00frd983h5rn56zs84bk41fax88sjq2gb02iw";
  };
  bootCfg = import (
    if builtins.pathExists ../secrets/boot.nix 
    then ../secrets/boot.nix 
    else ../secrets/boot.sample.nix);
in
{ lib, modulesPath, ... }:

{
  imports = [
    ./configuration.nix
    ./disco.nix
    "${diskoSrc}/module.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  disko = {
    imageBuilder = {
      name = "remnanode";
      imageFormat = "raw";
    };

    devices.disk.main.imageName = "remnanode";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = 
    if bootCfg.enableBootTty
    then [ "console=ttyS0,115200n8" ]
    else [ "quiet" "loglevel=0" "rd.udev.log_level=0" "udev.log_priority=0" ];
  systemd.services."serial-getty@ttyS0".enable = bootCfg.enableBootTty;

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "9p"
    "9pnet_virtio"
    "virtiofs"
    "ahci"
    "sd_mod"
  ];

  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_rng"
  ];

  # LUKS root
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-partlabel/disk-main-luks";
    keyFile = "/crypto_keyfile.bin";
    fallbackToPassword = false;
  };

  # включаем ключ в initrd
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = cryptrootKey;
  };

  services.qemuGuest.enable = bootCfg.enableGuest;
}
