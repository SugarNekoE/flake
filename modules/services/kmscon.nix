_: {
  nixos = {
    stylix.targets.kmscon.enable = true;
    services.kmscon = {
      enable = true;
      hwRender = true;
      extraConfig = ''
        font-size=24
      '';
    };
  };
}
