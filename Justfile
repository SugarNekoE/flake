set shell := ["bash", "-euo", "pipefail", "-c"]

# List the available project commands.
default:
    @just --list

# Require the generated flake entry point to be tracked by Git.
_require-tracked-flake:
    @if ! git ls-files --error-unmatch flake.nix >/dev/null 2>&1; then echo "flake.nix must be reviewed and tracked before flake-file can regenerate it."; exit 1; fi

# Refuse activation while the evaluation-only hardware stub is present.
_require-real-hardware:
    @if grep -Eq 'nodev|fsType = "tmpfs"' hardware/laptop.nix; then echo "Replace hardware/laptop.nix and add the real boot/filesystem or disko layout first."; exit 1; fi

# Regenerate flake.nix and normalize flake.lock with flake-file.
generate: _require-tracked-flake
    nix run .#write-flake

# Update every flake input, then regenerate and normalize generated files.
update: _require-tracked-flake
    nix flake update
    nix run .#write-flake

# Update one flake input, then regenerate and normalize generated files.
update-input input: _require-tracked-flake
    nix flake update "{{ input }}"
    nix run .#write-flake

# Run all flake-file and NixOS evaluation checks.
check:
    nix flake check path:.

# Show the flake output tree.
show:
    nix flake show path:.

# Generate local hardware facts to a reviewable file outside the repository.
generate-hardware output="/tmp/laptop-hardware.nix":
    sudo nixos-generate-config --show-hardware-config --no-filesystems > "{{ output }}"
    @echo "Generated {{ output }}. Review it before replacing hardware/laptop.nix."

# Generate hardware facts from an SSH target to a reviewable local file.
generate-hardware-remote target output="/tmp/laptop-hardware.nix":
    ssh "{{ target }}" "nix --extra-experimental-features nix-command --extra-experimental-features flakes shell nixpkgs#nixos-install-tools -c nixos-generate-config --show-hardware-config --no-filesystems" > "{{ output }}"
    @echo "Generated {{ output }} from {{ target }}. Review it before replacing hardware/laptop.nix."

# Preview what a laptop build would realize without building it.
dry-run hostname="laptop":
    nh os build --dry "path:.#{{ hostname }}"

# Build the laptop configuration without activating it.
build hostname="laptop":
    nh os build "path:.#{{ hostname }}"

# Build and activate the laptop configuration.
switch hostname="laptop": _require-real-hardware
    nh os switch "path:.#{{ hostname }}"

# Build the laptop configuration for the next boot without activating it now.
boot hostname="laptop": _require-real-hardware
    nh os boot "path:.#{{ hostname }}"
