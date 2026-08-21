{ pkgs, ... }:

{
  packages = with pkgs;[
    nixd
    nixfmt
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
    };
  };
}
