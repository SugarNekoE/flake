{
  nixos =
    { lib, ... }:
    let
      sopsFile = ../secrets/sing-box.json;
      hasConfig = builtins.pathExists sopsFile;
    in
    {
      sops.secrets.sing_box_config = lib.mkIf hasConfig {
        format = "json";
        inherit sopsFile;
        path = "/etc/sing-box/config.json";
        key = "";
        restartUnits = [ "sing-box.service" ];
      };
      services.sing-box.enable = hasConfig;
    };
}
