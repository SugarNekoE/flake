{ inputs, ... }:
let
  withProfile =
    { sopsFile }:
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.sing-box ];
      nixosModule =
        { lib, ... }:
        let
          hasProfile = builtins.pathExists sopsFile;
        in
        lib.mkIf hasProfile {
          sops.secrets.sing_box_config = {
            format = "json";
            inherit sopsFile;
            path = "/etc/sing-box/config.json";
            key = "";
            restartUnits = [ "sing-box.service" ];
          };
        };
    };
in
{
  aspectHelpers.sing-box = { inherit withProfile; };

  nixos.services.sing-box.enable = true;
}
