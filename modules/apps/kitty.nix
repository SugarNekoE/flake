_: {
  home =
    { ... }:
    {
      programs.kitty = {
        enable = true;
        settings = {
          background_opacity = 0.95;
          font_family = "NotoSansM Nerd Font Mono";
          initial_window_width = 1920;
          initial_window_height = 1080;
          font_size = 14.0;
        };
      };
    };
}
