# preinstalled-docker/yandex-cloud-image.nix
{ modulesPath, ... }:

{
  imports = [
    ./configuration.nix
    "${modulesPath}/virtualisation/disk-image.nix"
  ];

  image = {
    baseName = "preinstalled-docker-yandex-cloud";
    efiSupport = true;
  };
}
