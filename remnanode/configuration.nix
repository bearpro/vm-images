# remnanode/configuration.nix
{ config, pkgs, lib, ... }:

let 
  secrets = {
    user = import ../secrets/user.nix;
    remnanode = import ../secrets/remnanode.nix;
  };
  remnanodeWorkdir = "/opt/remnanode";
  remnanodeNodeImageTar = pkgs.dockerTools.pullImage {
    imageName = "remnawave/node";
    imageDigest = "sha256:fd1cc3d85bb16d56299676d2803ab21ef5fca2f8526fab792a6a16624d8b1543";
    finalImageName = "remnawave/node";
    finalImageTag = "2.7.0";
    outputHashAlgo = "sha256";
    outputHash = "sha256-79eogI1IphDfDKUYNfRwhMOfsMQ70VpnQV+WvdF0GXY=";
  };
  remnanodeNodeImageTarPath = "/etc/remnanode/remnawave-node-2.7.0.tar";
in 
{
  system.stateVersion = "25.11";

  networking.hostName = "nixos-remnanode";

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

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    htop
    cloud-init
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
      image: remnawave/node:2.7.0
      network_mode: host
      restart: always
      cap_add:
        - NET_ADMIN
      ulimits:
        nofile:
          soft: 1048576
          hard: 1048576
      environment:
        - NODE_PORT=${secrets.remnanode.port}
        - SECRET_KEY=${secrets.remnanode.secret}
  '';
  environment.etc."remnanode/remnawave-node-2.7.0.tar".source = remnanodeNodeImageTar;

  systemd.tmpfiles.rules = [
    "d ${remnanodeWorkdir} 0755 root root - -"
    "L+ ${remnanodeWorkdir}/docker-compose.yml - - - - /etc/remnanode/docker-compose.yml"
  ];

  systemd.services.remnanode = {
    description = "Remnanode in docker compose";
    after = [ "network-online.target" "docker.service" ];
    wants = [ "network-online.target" "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = remnanodeWorkdir;
      ExecStartPre = "${pkgs.docker}/bin/docker load -i ${remnanodeNodeImageTarPath}";
      ExecStart = "${pkgs.docker}/bin/docker compose up --pull never -d";
      ExecStop = "${pkgs.docker}/bin/docker compose down";
      TimeoutStartSec = "0";
      Restart = "on-failure";
    };
  };
}
