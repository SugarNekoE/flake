_: {
  nixos =
    { pkgs, ... }:
    {
      programs.fish.enable = true;
      stylix.targets.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    };

  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      colors = config.lib.stylix.colors;
    in
    {
      stylix.targets.fish.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = lib.mkAfter ''
          set -g fish_greeting
          fish_vi_key_bindings
          fzf_configure_bindings

          set -g fish_color_normal ${colors.base05}
          set -g fish_color_command ${colors.base0D} --bold
          set -g fish_color_keyword ${colors.base0E} --bold
          set -g fish_color_quote ${colors.base0B}
          set -g fish_color_redirection ${colors.base0C}
          set -g fish_color_end ${colors.base0E}
          set -g fish_color_error ${colors.base08} --bold
          set -g fish_color_param ${colors.base05}
          set -g fish_color_option ${colors.base0A}
          set -g fish_color_comment ${colors.base04} --italics
          set -g fish_color_selection ${colors.base05} --background=${colors.base02}
          set -g fish_color_operator ${colors.base0C}
          set -g fish_color_escape ${colors.base0E}
          set -g fish_color_autosuggestion ${colors.base04}
          set -g fish_color_cancel ${colors.base08}
          set -g fish_color_search_match ${colors.base00} --background=${colors.base0A}

          set -g fish_pager_color_progress ${colors.base0A} --bold
          set -g fish_pager_color_prefix ${colors.base0D} --bold
          set -g fish_pager_color_completion ${colors.base05}
          set -g fish_pager_color_description ${colors.base04}
          set -g fish_pager_color_selected_background --background=${colors.base02}
        '';
        shellAliases = {
          "ls" = "eza --icons";
          "ll" = "ls -lh";
          "la" = "ll -a";
          "tree" = "ls -T";
          "zed" = "zeditor";
          "z" = "cd";
          "cat" = "bat";
          "du" = "dust";
          "dig" = "doggo";
        };
        plugins = map (x: { inherit (x) name src; }) (
          with pkgs.fishPlugins;
          [
            fzf-fish
            plugin-git
            puffer
          ]
        );
      };
    };
}
