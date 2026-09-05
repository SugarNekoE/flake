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
    ruff
    yaml-language-server
    package-version-server
    vscode-json-languageserver
  ];

  env.SOPS_EDITOR = "zeditor --wait";

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
