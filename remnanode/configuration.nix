# preinstalled-docker/configuration.nix
{ config, pkgs, lib, ... }:

let 
  me = import ./me.nix;
  remnanodeWorkdir = "/opt/remnanode";
in 
{
  system.stateVersion = "25.11";

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

  users.users.${me.username} = {
    isNormalUser = true;
    description = "Main user";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    hashedPassword = me.hashedPassword;
    openssh.authorizedKeys.keys = me.authorizedKeys;
  };

  security.sudo.wheelNeedsPassword = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    htop
    docker
    docker-compose
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
    };
  };

  environment.etc."remnanode/docker-compose.yml".text = ''
    services:
    remnanode:
      container_name: remnanode
      hostname: remnanode
      image: remnawave/node:latest
      network_mode: host
      restart: always
      cap_add:
        - NET_ADMIN
      ulimits:
        nofile:
          soft: 1048576
          hard: 1048576
      environment:
        - NODE_PORT=${me.remnaNodePort}
        - SECRET_KEY=${me.remnaNodeSecret}
  '';

  systemd.tmpfiles.rules = [
    "d ${remnanodeWorkdir} 0755 root root - -"
    "L+ ${remnanodeWorkdir}/docker-compose.yml - - - - /etc/myapp/docker-compose.yml"
  ];

  systemd.services.docker-compose-myapp = {
    description = "Start my docker compose stack";
    after = [ "network-online.target" "docker.service" ];
    wants = [ "network-online.target" "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = remnanodeWorkdir;
      ExecStart = "${pkgs.docker}/bin/docker compose up -d";
      ExecStop = "${pkgs.docker}/bin/docker compose down";
      TimeoutStartSec = "0";
      Restart = "on-failure";
    };
  };
}

