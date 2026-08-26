_: {
  nixos =
    { pkgs, ... }:
    {
      programs.fish.enable = true;
      stylix.targets.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    };

  home =
    { pkgs, ... }:
    {
      stylix.targets.fish.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set -g fish_greeting
          fish_vi_key_bindings
          fzf_configure_bindings
        '';
        shellAliases = {
          "l" = "ls -lh";
          "ll" = "ls -lha";
          "la" = "ls -la";
          "zed" = "zeditor";
          "z" = "cd";
        };
        plugins = map (x: { inherit (x) name src; }) (
          with pkgs.fishPlugins;
          [
            fzf-fish
            puffer
          ]
        );
      };
    };
}
