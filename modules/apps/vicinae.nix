_: {
  home = {
    stylix.targets.vicinae.enable = true;

    programs.vicinae = {
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
      };
    };
  };
}
