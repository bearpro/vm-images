SHELL := /usr/bin/env bash

.PHONY: help _dist-dir _key preinstalled-docker-yacloud preinstalled-docker-proxmox boot-preinstalled-docker-proxmox-local clean

help:
	@printf 'Make VM images'

_dist-dir:
	@mkdir -p ./dist

_key:
	dd if=/dev/random of=./cryptroot.key bs=4096 count=1

preinstalled-docker-yacloud: _dist-dir
	nix-build '<nixpkgs/nixos>' \
		-A config.system.build.image \
		-I nixos-config=./preinstalled-docker/yandex-cloud-image.nix \
		-o ./dist/preinstalled-docker-yacloud
	@echo
	@echo "Built yacloud image:"
	@readlink -f ./dist/preinstalled-docker-yacloud

preinstalled-docker-proxmox: _dist-dir
	@rm -f ./dist/preinstalled-docker-proxmox ./dist/preinstalled-docker-proxmox.raw ./dist/preinstalled-docker-proxmox.qcow2
	@( cd ./dist && "$$(nix-build '<nixpkgs/nixos>' \
		-A config.system.build.diskoImagesScript \
		-I nixos-config=../preinstalled-docker/proxmox-image.nix \
		--no-out-link)" )
	@qemu-img convert -f raw -O qcow2 -c ./dist/preinstalled-docker-proxmox.raw ./dist/preinstalled-docker-proxmox.qcow2
	@echo
	@echo "Built proxmox images:"
	@readlink -f ./dist/preinstalled-docker-proxmox.raw
	@readlink -f ./dist/preinstalled-docker-proxmox.qcow2

boot-preinstalled-docker-proxmox-local: ./dist/preinstalled-docker-proxmox.qcow2
	@cp "$$(nix-build '<nixpkgs>' -A OVMF.fd --no-out-link)/FV/OVMF_VARS.fd" ./dist/preinstalled-docker-proxmox.ovmf-vars.fd
	@exec qemu-system-x86_64 \
		-name "preinstalled-docker-proxmox" \
		-machine q35,accel=kvm:tcg \
		-cpu max \
		-smp "2" \
		-m "2048" \
		-boot menu=on \
		-display none \
		-serial mon:stdio \
		-device virtio-rng-pci \
		-netdev user,id=net0 \
		-device virtio-net-pci,netdev=net0 \
		-drive if=pflash,format=raw,readonly=on,file="$$(nix-build '<nixpkgs>' -A OVMF.fd --no-out-link)/FV/OVMF_CODE.fd" \
		-drive if=pflash,format=raw,file="./dist/preinstalled-docker-proxmox.ovmf-vars.fd" \
		-device virtio-scsi-pci,id=scsi0 \
		-drive file="./dist/preinstalled-docker-proxmox.qcow2",if=none,id=vdisk,format="qcow2",cache=writeback \
		-device scsi-hd,drive=vdisk

clean:
	@rm -rf ./dist
