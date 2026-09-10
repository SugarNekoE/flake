{ inputs, lib, ... }:
let
  exaSopsFile = ../secrets/exa-key.yaml;
  hasExaKey = builtins.pathExists exaSopsFile;
in
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  nixos =
    { user, ... }:
    {
      nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];

      nix.settings = {
        extra-substituters = [ "https://cache.numtide.com" ];
        extra-trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };

      sops.secrets.exa-key = lib.mkIf hasExaKey {
        sopsFile = exaSopsFile;
        format = "yaml";
        key = "exa-key";
        owner = user.username;
        mode = "0400";
      };
    };

  home =
    { pkgs, ... }:
    {
      home = {
        packages = [
          pkgs.llm-agents.codex
          pkgs.llm-agents.chatgpt
          pkgs.bubblewrap
        ];
      };
    };
}
