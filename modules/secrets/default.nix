{ inputs, ... }:
{
  flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";

  nixos = {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops = {
      useSystemdActivation = true;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  home = {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
  };
}
