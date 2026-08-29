_: {
  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      stylix.targets.kitty = {
        enable = true;
        opacity.override.terminal = 1.0;
      };

      programs.kitty = {
        enable = true;
        shellIntegration.enableFishIntegration = true;
        font = {
          name = lib.mkForce "NotoMono Nerd Font";
          package = lib.mkForce pkgs.nerd-fonts.noto;
        };
        keybindings = {
          "ctrl+shift+f" = "send_key ctrl+shift+f";
          "ctrl+shift+h" = "send_key ctrl+shift+h";
          "ctrl+shift+j" = "send_key ctrl+shift+j";
          "ctrl+shift+k" = "send_key ctrl+shift+k";
          "ctrl+shift+l" = "send_key ctrl+shift+l";
          "ctrl+shift+t" = "send_key ctrl+shift+t";
        };
        settings = {
          font_size = 12;

          initial_window_width = 1920;
          initial_window_height = 1080;

          tab_bar_min_tabs = 1;
          tab_bar_edge = "bottom";
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
        };

        extraConfig = lib.mkAfter ''
          selection_foreground ${colors.base00}
          selection_background ${colors.base06}

          cursor ${colors.base06}
          cursor_text_color ${colors.base00}
          url_color ${colors.base06}

          scrollbar_handle_color ${colors.base04}
          scrollbar_track_color ${colors.base02}

          active_border_color ${colors.base07}
          inactive_border_color ${colors.base04}
          bell_border_color ${colors.base0A}

          active_tab_foreground ${colors.base01}
          active_tab_background ${colors.base0E}
          inactive_tab_foreground ${colors.base05}
          inactive_tab_background ${colors.base01}
          tab_bar_background ${colors.base01}

          mark1_foreground ${colors.base00}
          mark1_background ${colors.base07}
          mark2_foreground ${colors.base00}
          mark2_background ${colors.base0E}
          mark3_foreground ${colors.base00}
          mark3_background ${colors.base0D}
        '';
      };
    };
}
