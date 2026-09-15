_: {
  nixos = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      extraConfig.pipewire."99-hifi" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [
            44100
            48000
            88200
            96000
            176400
            192000
            352800
            384000
            768000
          ];
        };
      };
    };
    services.pulseaudio.enable = false;
  };

  home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.pavucontrol ];
    };
}
