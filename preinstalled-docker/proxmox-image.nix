# preinstalled-docker/proxmox-image.nix
let
  cryptrootKey = builtins.path {
    path = ../cryptroot.key;
    name = "cryptroot.key";
  };
  diskoSrc = builtins.fetchTarball {
    url = "https://github.com/nix-community/disko/archive/5ad85c82cc52264f4beddc934ba57f3789f28347.tar.gz";
    sha256 = "035nyq47jvhxf2d00frd983h5rn56zs84bk41fax88sjq2gb02iw";
  };
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
      name = "preinstalled-docker-proxmox";
      imageFormat = "raw";
    };

    devices.disk.main.imageName = "preinstalled-docker-proxmox";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # The disko image builder installs systemd-boot, but the resulting image
  # does not end up with initrd secrets appended as a separate initrd entry.
  # Force embedding the LUKS key into the primary initrd for this target.
  boot.loader.supportsInitrdSecrets = lib.mkForce false;
  boot.kernelParams = [
    "console=ttyS0,115200n8"
  ];
  systemd.services."serial-getty@ttyS0".enable = true;

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

  services.qemuGuest.enable = true;
}
