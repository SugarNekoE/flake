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

  languages = {
    go = {
      enable = true;
      version = "1.26.0";
    };
  };

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
