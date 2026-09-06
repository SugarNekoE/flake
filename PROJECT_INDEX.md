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

## ACS

**Go handles operations and checks. Nix only packages the CLI and runner images.**

| Path | Purpose |
| --- | --- |
| [Deployment guide](acs-k8s/acs-deployment-guide.md) | Setup, deployment, pool management and troubleshooting |
| [Operator example](acs-k8s/acs-config.example.json) | Template for ignored `acs-config.json` |
| [Deployment example](acs-k8s/acs-deployment.example.json) | Template for ignored `acs-deployment.json`; fill image references |
| [CLI aspect](modules/apps/acs-cli.nix) | Home Manager installation and package outputs |
| [Image builder](acs-k8s/nix/runner-image.nix) | Runner image packaging |
| [CLI entry](acs-k8s/cli/cmd/acs/main.go) | Executable entry point |
| [Go implementation](acs-k8s/cli/internal/app) | Configuration, manifests, bundles, SOPS, deployment, workflows and Kind |
| [Embedded assets](acs-k8s/cli/internal/app/assets) | Pinned KEDA chart and Kind registry fixture |
| [Test fixtures](acs-k8s/cli/internal/app/testdata/nix-reference) | Former Nix outputs for regression comparison |

Checks: `acs validate cli`, `acs validate platform`, `acs validate images`.
Go tests are beside the implementation. Generated YAML snapshots stay versioned.
Full Kind acceptance remains pending; Service routing was the last reported blocker.
