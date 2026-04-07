# preinstalled-docker/configuration.nix
{ config, pkgs, lib, ... }:

let 
  secrets = {
    user = import ../secrets/user.nix;
  };
in 
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

  users.users.${secrets.user.username} = {
    isNormalUser = true;
    description = "Main user";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    hashedPassword = secrets.user.hashedPassword;
    openssh.authorizedKeys.keys = secrets.user.authorizedKeys;
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

