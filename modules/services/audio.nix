_: {
  nixos = { user, ... }: {
    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      systemWide = true;
      alsa.enable = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      extraConfig.pipewire."99-sample-rate" = {
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
    users.users.${user.username}.extraGroups = [ "pipewire" ];
  };

  home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.pavucontrol ];
    };
}
