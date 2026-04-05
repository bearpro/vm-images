let
  cryptrootKey = builtins.path {
    path = ./cryptroot.key;
    name = "cryptroot.key";
  };
in
{ ... }:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/vda";
      imageSize = "8G";

      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              initrdUnlock = false;

              settings = {
                allowDiscards = false;
                keyFile = builtins.toString cryptrootKey;
              };

              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
