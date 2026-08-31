_: {
  nixos =
    { user, ... }:
    {
      sops.secrets."znc-irc-password" = {
        sopsFile = ../secrets/znc-irc.yaml;
        format = "yaml";
        key = "password";
        owner = user.username;
        mode = "0400";
      };
    };

  home =
    {
      config,
      nixosConfig,
      ...
    }:
    let
      colors = config.lib.stylix.colors.withHashtag;
      passwordFile = nixosConfig.sops.secrets."znc-irc-password".path;
    in
    {
      programs.halloy = {
        enable = true;

        settings = {
          theme = "stylix";

          font = {
            family = config.stylix.fonts.monospace.name;
            size = config.stylix.fonts.sizes.terminal;
          };

          servers = {
            libera = {
              server = "sugar.znchost.com";
              port = 4000;
              use_tls = true;
              nickname = "asaineko";
              realname = "Asai Neko";
              username = "snemeow/liberachat";
              password_file = passwordFile;
            };
            oftc = {
              server = "sugar.znchost.com";
              port = 4000;
              use_tls = true;
              nickname = "asaineko";
              realname = "Asai Neko";
              username = "snemeow/oftc";
              password_file = passwordFile;
            };
          };
        };

        themes.stylix = {
          general = {
            background = colors.base00;
            border = colors.base02;
            horizontal_rule = colors.base02;
            horizontal_rule_text = colors.base04;
            scrollbar = colors.base03;
            unread_indicator = colors.base0D;
            highlight_indicator = colors.base0A;
          };

          text = {
            primary = colors.base05;
            secondary = colors.base04;
            tertiary = colors.base03;
            success = colors.base0B;
            error = colors.base08;
            warning = colors.base0A;
            info = colors.base0D;
            debug = colors.base0E;
            trace = colors.base03;
          };

          buttons = {
            primary = {
              background = colors.base00;
              background_hover = colors.base01;
              background_selected = colors.base02;
              background_selected_hover = colors.base03;
              border_active = colors.base0D;
            };
            secondary = {
              background = colors.base01;
              background_hover = colors.base02;
              background_selected = colors.base03;
              background_selected_hover = colors.base04;
              border_active = colors.base0D;
            };
          };

          buffer = {
            background = colors.base00;
            background_text_input = colors.base01;
            background_title_bar = colors.base01;
            border = colors.base02;
            border_selected = colors.base0D;
            action = colors.base0B;
            code = colors.base0C;
            highlight = colors.base02;
            nickname = colors.base0E;
            nickname_offline = colors.base03;
            selection = colors.base02;
            timestamp = colors.base03;
            topic = colors.base04;
            url = colors.base0D;
            backlog_rule = colors.base02;
            backlog_rule_text = colors.base04;
            date_rule = colors.base02;
            date_rule_text = colors.base04;
            server_messages.default = colors.base0A;
          };

          formatting = {
            white = colors.base07;
            black = colors.base00;
            blue = colors.base0D;
            green = colors.base0B;
            red = colors.base08;
            brown = colors.base0F;
            magenta = colors.base0E;
            orange = colors.base09;
            yellow = colors.base0A;
            lightgreen = colors.base0B;
            cyan = colors.base0C;
            lightcyan = colors.base0C;
            lightblue = colors.base0D;
            pink = colors.base0E;
            grey = colors.base03;
            lightgrey = colors.base04;
          };
        };
      };
    };
}
