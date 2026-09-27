# Project index

Personal NixOS/Home Manager flake. Modules use selectable `nixos`/`home` aspects;
`flake.nix` is generated through flake-file.

## Repository

| Path | Purpose |
| --- | --- |
| [modules/aspects.nix](modules/aspects.nix) | Module discovery, aspect selection and host assembly |
| [modules/default.nix](modules/default.nix) | Flake input/output declarations |
| [modules/apps](modules/apps), [services](modules/services), [roles](modules/roles) | Applications, host services and bundles |
| [modules/machines](modules/machines) | Hosts; `daisy` uses Sway, `fern` uses Plasma |
| [modules/system](modules/system) | Hardware, disks, mounts and system settings |
| [modules/users](modules/users), [identity](modules/identity) | Users and public identities |
| [modules/secrets](modules/secrets) | SOPS-encrypted secrets; do not decrypt during inspection |
| [modules/lib/qcow2.nix](modules/lib/qcow2.nix) | QCOW2 image helper |
| [devenv.nix](devenv.nix), [Justfile](Justfile) | Development tools and host commands |
