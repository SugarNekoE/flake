_: {
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nerd-fonts.noto
      ];

      programs.kitty = {
        enable = true;
        settings = {
          background_opacity = 0.95;
          font_family = "Noto Sans Mono NF";
          initial_window_width = 1920;
          initial_window_height = 1080;
          font_size = 12.0;
        };
      };
    };
}
