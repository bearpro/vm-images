SHELL := /usr/bin/env bash

show-last:
	@test -f "./dist/last-image-name" || { echo "Nothing built"; exit 1; }
	@echo "Last image: $$(cat "./dist/last-image-name")"
	@echo "RAW:  $$(readlink -f "./dist/last.raw")"
	@echo "QCOW: $$(readlink -f "./dist/last.qcow2")"

_dist-dir:
	@mkdir -p ./dist

_key:
	@dd if=/dev/random of=./secrets/cryptroot.key bs=4096 count=1
	@echo 'Regenerated ./secrets/cryptroot.key'

define build-image
	@rm -f "./dist/$(1).raw" "./dist/$(1).qcow2"
	$$(nix-build '<nixpkgs/nixos>' \
		-A config.system.build.diskoImagesScript \
		-I nixos-config=./$(1)/image.nix \
		--no-out-link)
	@mv ./$(1).raw ./dist/$(1).raw
	@qemu-img convert -f raw -O qcow2 -c "./dist/$(1).raw" "./dist/$(1).qcow2"
	@ln -sfn "$(1).raw" "./dist/last.raw"
	@ln -sfn "$(1).qcow2" "./dist/last.qcow2"
	@printf '%s\n' "$(1)" > "./dist/last-image-name"
	@echo "Built images:"
	@readlink -f "./dist/$(1).raw"
	@readlink -f "./dist/$(1).qcow2"
endef

preinstalled-docker: _key _dist-dir
	$(call build-image,preinstalled-docker)

remnanode: _key _dist-dir
	$(call build-image,remnanode)

define boot-last
	@test -L "./dist/last.$(1)" || { echo "No last.$(1) found"; exit 1; }
	@set -euo pipefail; \
	ovmf_dir="$$(nix-build '<nixpkgs>' -A OVMF.fd --no-out-link)/FV"; \
	vars_file="$$(mktemp ./dist/last-$(1).ovmf-vars.XXXXXX.fd)"; \
	trap 'rm -f "$$vars_file"' EXIT; \
	cp "$$ovmf_dir/OVMF_VARS.fd" "$$vars_file"; \
	qemu-system-x86_64 \
		-name "last-$(1)" \
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
		-drive if=pflash,format=raw,readonly=on,file="$$ovmf_dir/OVMF_CODE.fd" \
		-drive if=pflash,format=raw,file="$$vars_file" \
		-device virtio-scsi-pci,id=scsi0 \
		-drive file="./dist/last.$(1)",if=none,id=vdisk,format=$(1),cache=writeback \
		-device scsi-hd,drive=vdisk
endef

boot-last-qcow: ./dist/last.qcow2
	$(call boot-last,qcow2)

boot-last-raw: ./dist/last.raw
	$(call boot-last,raw)

clean:
	@rm -rf ./dist ./*.raw
