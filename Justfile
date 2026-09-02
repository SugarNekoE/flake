set shell := ["bash", "-euo", "pipefail", "-c"]

# List project commands.
default:
    @just --list

# Require the generated flake entry point to be tracked by Git.
_require-tracked-flake:
    @if ! git ls-files --error-unmatch flake.nix >/dev/null 2>&1; then echo "flake.nix must be reviewed and tracked before flake-file can regenerate it."; exit 1; fi

# Regenerate flake.nix and normalize flake.lock.
generate: _require-tracked-flake
    nix run path:.#write-flake

# Update every flake input, then regenerate generated files.
update: _require-tracked-flake
    nix flake update
    nix run path:.#write-flake

# Update one flake input, then regenerate generated files.
update-input input: _require-tracked-flake
    nix flake update "{{ input }}"
    nix run path:.#write-flake

# Run flake-file and NixOS evaluation checks.
check:
    nix flake check path:.

# Show the flake output tree.
show:
    nix flake show path:.

# List available NixOS machine configurations.
hosts:
    @nix eval path:.#nixosConfigurations --apply builtins.attrNames

# Fully evaluate a machine's system derivation without building it.
evaluate hostname:
    nix eval --raw "path:.#nixosConfigurations.{{ hostname }}.config.system.build.toplevel.drvPath"

# Generate local hardware facts outside the repository.
generate-hardware output="/tmp/hardware.nix":
    sudo nixos-generate-config --show-hardware-config --no-filesystems > "{{ output }}"

# Generate hardware facts from an SSH target outside the repository.
generate-hardware-remote target output="/tmp/hardware.nix":
    ssh "{{ target }}" "nix --extra-experimental-features nix-command --extra-experimental-features flakes shell nixpkgs#nixos-install-tools -c nixos-generate-config --show-hardware-config --no-filesystems" > "{{ output }}"

# Preview a machine build without realizing it.
dry-run hostname:
    nh os build --dry "path:.#{{ hostname }}"

# Build a machine without activating it.
build hostname:
    nh os build "path:.#{{ hostname }}"

# Build a machine's qcow2 image in the Nix store.
build-qcow2 hostname:
    nix build "path:.#qcow2Configurations.{{ hostname }}.config.system.build.diskoImages"

# Build the script that creates a machine's writable qcow2 image.
build-qcow2-script hostname:
    nix build "path:.#qcow2Configurations.{{ hostname }}.config.system.build.diskoImagesScript"

# Build and activate a machine locally.
switch hostname:
    nh os switch "path:.#{{ hostname }}"

# Build a machine and activate it on the next boot.
boot hostname:
    nh os boot "path:.#{{ hostname }}"

# Build, copy, and activate a machine configuration over SSH.
deploy hostname target:
    nh os switch --target-host "{{ target }}" "path:.#{{ hostname }}"

# Build and copy a machine configuration over SSH, activating it on the next boot.
deploy-boot hostname target:
    nh os boot --target-host "{{ target }}" "path:.#{{ hostname }}"

# Destructively install a machine over SSH while preserving its SSH host keys.
install hostname target:
    nix run github:nix-community/nixos-anywhere -- --flake "path:.#{{ hostname }}" --target-host "{{ target }}" --copy-host-keys

# Install with an additional root tree copied into the target installation.
install-with-files hostname target files:
    nix run github:nix-community/nixos-anywhere -- --flake "path:.#{{ hostname }}" --target-host "{{ target }}" --copy-host-keys --extra-files "{{ files }}"

# Install with a local disk-encryption key copied into the installer environment.
install-encrypted hostname target key_file remote_path="/tmp/disko-luks-password":
    nix run github:nix-community/nixos-anywhere -- --flake "path:.#{{ hostname }}" --target-host "{{ target }}" --copy-host-keys --disk-encryption-keys "{{ remote_path }}" "{{ key_file }}"

# Install with disk encryption and an additional root tree.
install-encrypted-with-files hostname target key_file files remote_path="/tmp/disko-luks-password":
    nix run github:nix-community/nixos-anywhere -- --flake "path:.#{{ hostname }}" --target-host "{{ target }}" --copy-host-keys --disk-encryption-keys "{{ remote_path }}" "{{ key_file }}" --extra-files "{{ files }}"

# Interactively install a LUKS machine with SOPS and SSH bootstrap files.
anywhere hostname target:
    #!/usr/bin/env bash
    set -euo pipefail

    machine="{{ hostname }}"
    ssh_target="{{ target }}"
    age_key="$HOME/.config/sops/age/keys.txt"

    if [[ ! -f "$age_key" ]]; then
      echo "Missing SOPS age key: $age_key" >&2
      exit 1
    fi

    nix eval --raw "path:.#nixosConfigurations.$machine.config.system.build.toplevel.drvPath" >/dev/null
    luks_remote_path=""
    if luks_remote_path=$(nix eval --raw "path:.#nixosConfigurations.$machine.config.disko.devices.disk.system.content.partitions.root.content.passwordFile" 2>/dev/null); then
      uses_luks=true
    else
      uses_luks=false
    fi

    echo "Target disks:"
    ssh "$ssh_target" 'if [[ $(id -u) -eq 0 ]]; then lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS; else sudo -n lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS; fi'
    echo
    echo "WARNING: nixos-anywhere will destroy the disks selected by '$machine'."
    read -r -p "Type $machine to continue: " confirmation
    [[ "$confirmation" == "$machine" ]] || { echo "Cancelled."; exit 1; }

    ssh_password="${SSHPASS:-}"
    if [[ -z "$ssh_password" ]]; then
      read -r -s -p "Target SSH password: " ssh_password
      echo
    fi
    [[ -n "$ssh_password" ]] || { echo "The target SSH password cannot be empty." >&2; exit 1; }

    if [[ "$uses_luks" == true ]]; then
      echo "LUKS detected; the installer expects its password at $luks_remote_path."
      while true; do
        read -r -s -p "New LUKS password: " luks_password
        echo
        read -r -s -p "Confirm LUKS password: " luks_confirmation
        echo
        if [[ -n "$luks_password" && "$luks_password" == "$luks_confirmation" ]]; then
          break
        fi
        echo "Passwords did not match or were empty; try again." >&2
      done
    else
      echo "No LUKS password file configured; skipping disk-encryption key setup."
    fi

    luks_key_file=""
    extra_files_dir=$(mktemp -d /tmp/nixos-anywhere-extra.XXXXXX)
    cleanup() {
      if [[ "$luks_key_file" == /tmp/nixos-anywhere-luks.* ]]; then
        rm -f -- "$luks_key_file"
      fi
      if [[ "$extra_files_dir" == /tmp/nixos-anywhere-extra.* ]]; then
        rm -rf -- "$extra_files_dir"
      fi
    }
    trap cleanup EXIT

    if [[ "$uses_luks" == true ]]; then
      luks_key_file=$(mktemp /tmp/nixos-anywhere-luks.XXXXXX)
      chmod 600 "$luks_key_file"
      printf '%s' "$luks_password" > "$luks_key_file"
      unset luks_password luks_confirmation
    fi

    install -D -m 600 "$age_key" "$extra_files_dir/var/lib/sops-nix/key.txt"
    install -d -m 700 "$extra_files_dir/root/.ssh"
    authorized_keys="$extra_files_dir/root/.ssh/authorized_keys"
    if ! ssh-add -L > "$authorized_keys"; then
      echo "The default SSH agent did not expose a public key." >&2
      exit 1
    fi
    [[ -s "$authorized_keys" ]] || { echo "No SSH public keys found." >&2; exit 1; }
    chmod 600 "$authorized_keys"

    anywhere_args=(
      --flake "path:.#$machine"
      --target-host "$ssh_target"
      --copy-host-keys
      --extra-files "$extra_files_dir"
      --env-password
    )
    if [[ "$uses_luks" == true ]]; then
      anywhere_args+=(--disk-encryption-keys "$luks_remote_path" "$luks_key_file")
    fi

    SSHPASS="$ssh_password" nix run github:nix-community/nixos-anywhere -- "${anywhere_args[@]}"
