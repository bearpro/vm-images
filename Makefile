SHELL := /usr/bin/env bash

help:
	@printf 'Make VM images'

_dist-dir:
	@mkdir -p ./dist

preinstalled-docker-yacloud: _dist-dir
	nix-build '<nixpkgs/nixos>' \
		-A config.system.build.image \
		-I nixos-config=./preinstalled-docker/yandex-cloud-image.nix \
		-o ./dist/preinstalled-docker-yacloud
	@echo
	@echo "Built yacloud image:"
	@readlink -f /dist/preinstalled-docker-yacloud

preinstalled-docker-proxmox: _dist-dir
	nix-build '<nixpkgs/nixos>' \
		-A config.system.build.image \
		-I nixos-config=./preinstalled-docker/proxmox-image.nix \
		-o ./dist/preinstalled-docker-proxmox
	@echo
	@echo "Built proxmox image:"
	@readlink -f ./dist/preinstalled-docker-proxmox

clean:
	@rm -rf "./dist"

