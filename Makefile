SHELL := /usr/bin/env bash

DIST_DIR := ./dist
PROXMOX_IMAGE_BASENAME := preinstalled-docker-proxmox
PROXMOX_RAW_IMAGE := $(DIST_DIR)/$(PROXMOX_IMAGE_BASENAME).raw
PROXMOX_QCOW2_IMAGE := $(DIST_DIR)/$(PROXMOX_IMAGE_BASENAME).qcow2
OVMF_FD_DIR := $(shell nix-build '<nixpkgs>' -A OVMF.fd --no-out-link)
OVMF_CODE := $(OVMF_FD_DIR)/FV/OVMF_CODE.fd
OVMF_VARS := $(OVMF_FD_DIR)/FV/OVMF_VARS.fd
QEMU_DISK_IMAGE ?= $(PROXMOX_QCOW2_IMAGE)
QEMU_DISK_FORMAT ?= qcow2
QEMU_MEMORY ?= 2048
QEMU_CPUS ?= 2

help:
	@printf 'Make VM images'

_dist-dir:
	@mkdir -p $(DIST_DIR)

preinstalled-docker-yacloud: _dist-dir
	nix-build '<nixpkgs/nixos>' \
		-A config.system.build.image \
		-I nixos-config=./preinstalled-docker/yandex-cloud-image.nix \
		-o ./dist/preinstalled-docker-yacloud
	@echo
	@echo "Built yacloud image:"
	@readlink -f /dist/preinstalled-docker-yacloud

preinstalled-docker-proxmox: _dist-dir
	@script_path="$$(nix-build '<nixpkgs/nixos>' \
		-A config.system.build.diskoImagesScript \
		-I nixos-config=./preinstalled-docker/proxmox-image.nix \
		--no-out-link)"; \
	rm -f "$(DIST_DIR)/$(PROXMOX_IMAGE_BASENAME)" "$(PROXMOX_RAW_IMAGE)" "$(PROXMOX_QCOW2_IMAGE)"; \
	( cd "$(DIST_DIR)" && "$$script_path" ); \
	qemu-img convert -f raw -O qcow2 -c "$(PROXMOX_RAW_IMAGE)" "$(PROXMOX_QCOW2_IMAGE)"
	@echo
	@echo "Built proxmox images:"
	@readlink -f "$(PROXMOX_RAW_IMAGE)"
	@readlink -f "$(PROXMOX_QCOW2_IMAGE)"

boot-preinstalled-docker-proxmox-local: $(PROXMOX_QCOW2_IMAGE)
	@vars="$$(mktemp /tmp/preinstalled-docker-proxmox-ovmf-vars.XXXXXX.fd)"; \
	cp "$(OVMF_VARS)" "$$vars"; \
	trap 'rm -f "$$vars"' EXIT; \
	exec qemu-system-x86_64 \
		-name "$(PROXMOX_IMAGE_BASENAME)" \
		-machine q35,accel=kvm:tcg \
		-cpu max \
		-smp "$(QEMU_CPUS)" \
		-m "$(QEMU_MEMORY)" \
		-boot menu=on \
		-display none \
		-serial mon:stdio \
		-device virtio-rng-pci \
		-netdev user,id=net0 \
		-device virtio-net-pci,netdev=net0 \
		-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
		-drive if=pflash,format=raw,file="$$vars" \
		-device virtio-scsi-pci,id=scsi0 \
		-drive file="$(QEMU_DISK_IMAGE)",if=none,id=vdisk,format="$(QEMU_DISK_FORMAT)",cache=writeback \
		-device scsi-hd,drive=vdisk

clean:
	@rm -rf "$(DIST_DIR)"
