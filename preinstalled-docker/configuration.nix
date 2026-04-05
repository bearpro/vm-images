# preinstalled-docker/configuration.nix
{ config, pkgs, lib, ... }:

{
  system.stateVersion = "25.05";

  networking.hostName = "nixos-vm";
  networking.useDHCP = lib.mkDefault true;

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.bearpro = {
    isNormalUser = true;
    description = "Main user";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    hashedPassword = "$y$j9T$.QS8PZgHxvYBho/cAF.if/$Iw2IOzEHXBQiCiZ.yACUJy8bm2Ba.GSKgqPPHuG79N/";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1TqNEvOYQLDfhwzxj/Kus+13mWfZRX2EF+6Ds/ziXUV6W7zTjW8XBbLGO4Pp48hx4j9Tg0C5stsKPGb8OieQE1UuPvyKI78Q3Stv6mpMBgxWShYLlJmMFt7l5Zgw9WH0RrBRjZOaPFMQ9byAuOo8/wlpQx9m8Ii44NVrqnDEroZyp4TUpo0UCUHm7QWJXxQsIsC8nzwpHYDtZlfwVp6Kg4ht2qLz45pWflw1nJ5Q+nZv8LS86+Ai8AAqRArRH101cB1RROFx+zb3t5rxwAgUXDAmTyWyjlUohKgRft7UCS/1qUv/GZw5VZBidRmqKx7Ly0caEFevJ1ER76HZEWP9YWyH+cdjjYNfphIk8x9yehKufProKzay19LgNTf4ry9QU4cr+bknzIrdgjFBLaXWDHnlfWrSlUJbwH13v12Vfq5WVoO4Bjh1wyowymVG9c61c6cxoRWlw4WnG6rzy7jJRYW+Tx/cy/D52EFoIowrGb5QQkBcDAW1/zU42naJpCFE= bearpro@dt-bearpro"
    ];
  };

  security.sudo.wheelNeedsPassword = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    htop
  ];
}

