set shell := ["bash", "-euo", "pipefail", "-c"]

# List project commands.
default:
    @just --list

# Require the generated flake entry point to be tracked by Git.
_require-tracked-flake:
    @if ! git ls-files --error-unmatch flake.nix >/dev/null 2>&1; then echo "flake.nix must be reviewed and tracked before flake-file can regenerate it."; exit 1; fi

# Regenerate flake.nix.
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
generate-hardware-remote target output="/tmp/hardware.nix" port="22":
    ssh -p "{{ port }}" "{{ target }}" "nix --extra-experimental-features nix-command --extra-experimental-features flakes shell nixpkgs#nixos-install-tools -c nixos-generate-config --show-hardware-config --no-filesystems" > "{{ output }}"

# Preview a machine build without realizing it.
dry-run hostname:
    nh os build --dry "path:.#{{ hostname }}"

# Build a machine without activating it.
build hostname:
    nh os build "path:.#{{ hostname }}"

# Build a machine's qcow2 image in the Nix store.
build-qcow2 hostname:
    nix build "path:.#qcow2Configurations.{{ hostname }}.config.system.build.diskoImages"

# Build a machine's writable qcow2 image script as <hostname>-result.
build-qcow2-script hostname:
    nix build --out-link "{{ hostname }}-result" "path:.#qcow2Configurations.{{ hostname }}.config.system.build.diskoImagesScript"

# Build and activate a machine locally.
switch hostname:
    nh os switch "path:.#{{ hostname }}"

# Build a machine and activate it on the next boot.
boot hostname:
    nh os boot "path:.#{{ hostname }}"

# Build, copy, and activate a machine configuration over SSH.
deploy hostname target port="22":
    NH_SSHOPTS="-p {{ port }} ${NH_SSHOPTS:-${NIX_SSHOPTS:-}}" nh os switch --target-host "{{ target }}" "path:.#{{ hostname }}"

# Build and copy a machine configuration over SSH, activating it on the next boot.
deploy-boot hostname target port="22":
    NH_SSHOPTS="-p {{ port }} ${NH_SSHOPTS:-${NIX_SSHOPTS:-}}" nh os boot --target-host "{{ target }}" "path:.#{{ hostname }}"

# Destructively install a machine over SSH, passing extra flags to nixos-anywhere.
[positional-arguments]
install hostname target port="22" *args:
    nixos-anywhere --flake "path:.#$1" --target-host "$2" --ssh-port "$3" --copy-host-keys "${@:4}"

# Interactively install a LUKS machine with SOPS and SSH bootstrap files.
[positional-arguments]
anywhere hostname target port="22" kexec_port="22" kexec_tarball="":
    #!/usr/bin/env bash
    set -euo pipefail

    machine=$1 ssh_target=$2 ssh_port=$3 kexec_port=$4 kexec_tarball=$5
    age_key="$HOME/.config/sops/age/keys.txt"
    [[ -f "$age_key" ]] || { echo "Missing SOPS age key: $age_key" >&2; exit 1; }

    luks_remote_path=$(nix eval --json "path:.#nixosConfigurations.$machine.config" --apply 'c: {
      drv = c.system.build.toplevel.drvPath;
      luks = c.disko.devices.disk.system.content.partitions.root.content.passwordFile or null;
    }' | jq -r '.luks // empty')

    ssh_password="${SSHPASS:-}"
    if [[ -z "$ssh_password" ]]; then
      read -r -s -p "Target SSH password: " ssh_password
      echo
    fi
    [[ -n "$ssh_password" ]] || { echo "The target SSH password cannot be empty." >&2; exit 1; }
    export SSHPASS=$ssh_password

    echo "Target disks:"
    sshpass -e ssh -p "$ssh_port" "$ssh_target" 'if [[ $(id -u) -eq 0 ]]; then lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS; else sudo -n lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS; fi'
    echo
    echo "WARNING: nixos-anywhere will destroy the disks selected by '$machine'."
    read -r -p "Type $machine to continue: " confirmation
    [[ "$confirmation" == "$machine" ]] || { echo "Cancelled."; exit 1; }

    work_dir=$(mktemp -d -p "${XDG_RUNTIME_DIR:-/tmp}" nixos-anywhere.XXXXXX)
    trap 'rm -rf -- "$work_dir"' EXIT

    anywhere_args=(
      --flake "path:.#$machine"
      --target-host "$ssh_target"
      --ssh-port "$ssh_port"
      --post-kexec-ssh-port "$kexec_port"
      --copy-host-keys
      --extra-files "$work_dir/extra"
      --env-password
    )
    [[ -z "$kexec_tarball" ]] || anywhere_args+=(--kexec "$kexec_tarball")

    if [[ -n "$luks_remote_path" ]]; then
      echo "LUKS detected; the installer expects its password at $luks_remote_path."
      while true; do
        read -r -s -p "New LUKS password: " luks_password
        echo
        read -r -s -p "Confirm LUKS password: " luks_confirmation
        echo
        [[ -n "$luks_password" && "$luks_password" == "$luks_confirmation" ]] && break
        echo "Passwords did not match or were empty; try again." >&2
      done
      printf '%s' "$luks_password" > "$work_dir/luks-key"
      unset luks_password luks_confirmation
      anywhere_args+=(--disk-encryption-keys "$luks_remote_path" "$work_dir/luks-key")
    else
      echo "No LUKS password file configured; skipping disk-encryption key setup."
    fi

    install -D -m 600 "$age_key" "$work_dir/extra/var/lib/sops-nix/key.txt"
    install -d -m 700 "$work_dir/extra/root/.ssh"
    ssh-add -L > "$work_dir/extra/root/.ssh/authorized_keys" || { echo "The default SSH agent did not expose a public key." >&2; exit 1; }
    chmod 600 "$work_dir/extra/root/.ssh/authorized_keys"

    nixos-anywhere "${anywhere_args[@]}"
