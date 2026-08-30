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
    package-version-server
    vscode-json-languageserver
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
