{ inputs, ... }:
{
  flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";

  nixos = {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops = {
      useSystemdActivation = true;
      age.keyFile = "/var/lib/sops-nix/key.txt";
    };
  };
}
