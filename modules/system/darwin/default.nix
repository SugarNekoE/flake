{ inputs, ... }:
{
  flake-file.inputs = {
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  };

  darwin =
    { config, lib, ... }:
    {
      homebrew = {
        enable = lib.mkDefault true;
        onActivation.cleanup = "none";
      };

      nixpkgs.config.allowUnfree = true;

      nix = lib.mkIf config.nix.enable {
        channel.enable = false;
        registry.sugar.flake = inputs.self;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          extra-substituters = [ "https://nix-community.cachix.org" ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          trusted-users = [ "@admin" ];
        };
      };
    };
}
