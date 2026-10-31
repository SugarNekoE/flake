{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
  };

  nixos = {
    nixpkgs.overlays = [
      (_final: stable: {
        llm-agents = inputs.llm-agents.packages.${stable.stdenv.hostPlatform.system};
      })
    ];
  };
}
