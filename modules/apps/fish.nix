_: {
  nixos =
    { pkgs, ... }:
    {
      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    };

  home =
    { pkgs, ... }:
    {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting # Disable greeting
        '';
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
