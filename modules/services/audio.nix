_: {
  nixos = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    services.pulseaudio.enable = false;
  };

  home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.pavucontrol ];
    };
}
