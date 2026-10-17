_: {
  nixos = {
    services.sdrplayApi.enable = true;
  };
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        (sdrpp.override {
          sdrplay_source = true;
        })
      ];
    };
}
