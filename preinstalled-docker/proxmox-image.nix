# preinstalled-docker/proxmox-image.nix
{ modulesPath, ... }:

{
  imports = [
    ./configuration.nix
    "${modulesPath}/virtualisation/disk-image.nix"
  ];

  image = {
    baseName = "preinstalled-docker-proxmox";
    efiSupport = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "ahci"
    "sd_mod"
  ];

  services.qemuGuest.enable = true;
}

