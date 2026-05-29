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
  
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22
      80
      443
      (lib.toInt secrets.remnanode.port)
    ];

    allowedUDPPorts = [ 443 ];
  };

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
    # system
    cloud-init
    openssl

    # util
    git
    curl
    wget
    neovim
    htop
    tmux

    # network
    tcpdump
    nmap
    mtr
    traceroute
    iperf3
    socat
    netcat-openbsd
    ethtool
    whois
    dig

    # docker
    docker
    docker-compose
    
    # nginx
    nginx
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
    # remnanode
    "d ${remnanodeWorkdir} 0755 root root - -"
    "L+ ${remnanodeWorkdir}/docker-compose.yml - - - - /etc/remnanode/docker-compose.yml"
  ];

  system.activationScripts.mutableNginxDefaults.text = ''
    # Nginx directories
    ${pkgs.coreutils}/bin/install -d -m 0755 -o root -g root /etc/nginx
    ${pkgs.coreutils}/bin/install -d -m 0755 -o root -g root /etc/nginx/conf.d
    ${pkgs.coreutils}/bin/install -d -m 0755 -o root -g root /etc/nginx/certs

    # Default http server
    if [ ! -e /etc/nginx/conf.d/default.conf ]; then
      cat > /etc/nginx/conf.d/default.conf <<'EOF'
    server {
        listen 80 default_server;
        server_name _;

        return 301 https://$host$request_uri;
    }

    server {
        listen 127.0.0.1:442 ssl default_server;
        server_name _;

        ssl_certificate     /etc/nginx/certs/fallback.crt;
        ssl_certificate_key /etc/nginx/certs/fallback.key;

        return 401;
    }
    EOF
    fi

    # Default stream config
    if [ ! -e /etc/nginx/stream.conf ]; then
      cat > /etc/nginx/stream.conf <<'EOF'
    map $ssl_preread_server_name $backend {
        default 127.0.0.1:442;
    }

    server {
        listen 0.0.0.0:443;
        proxy_pass $backend;
        ssl_preread on;
    }
    EOF
    fi
    
    # Fallback cert
    if [ ! -e /etc/nginx/certs/fallback.key ]; then
      ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout /etc/nginx/certs/fallback.key \
        -out /etc/nginx/certs/fallback.crt \
        -days 3650 \
        -subj "/CN=default.invalid"

      chmod 600 /etc/nginx/certs/fallback.key
      chmod 644 /etc/nginx/certs/fallback.crt
      chown nginx:nginx /etc/nginx/certs/fallback.key /etc/nginx/certs/fallback.crt
    fi
  '';

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

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    streamConfig = ''
      include /etc/nginx/stream.conf;
    '';

    appendHttpConfig = ''
      include /etc/nginx/conf.d/*.conf;
    '';
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
  '';
}
