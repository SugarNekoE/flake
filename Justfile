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

# Build and activate a machine locally.
switch hostname:
    nh os switch "path:.#{{ hostname }}"

# Build a machine and activate it on the next boot.
boot hostname:
    nh os boot "path:.#{{ hostname }}"

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
