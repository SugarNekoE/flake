{ pkgs, ... }:

{
  packages = with pkgs; [
    nil
    nixd
    just
    nh
    sops
    age
    ssh-to-age
    nixos-rebuild-ng
    uv
  ];

  git-hooks = {
    enable = true;
    hooks = {
      convco = {
        enable = true;
      };
      nixfmt.enable = true;
      statix.enable = true;
    };
  };
}
