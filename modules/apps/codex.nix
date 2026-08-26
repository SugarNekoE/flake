{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  nixos = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };

  home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.llm-agents.codex ];
    };
}
