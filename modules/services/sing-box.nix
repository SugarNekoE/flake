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

  nixos =
    { pkgs, ... }:
    {
      services.sing-box = {
        enable = true;
        package = pkgs.sing-box.overrideAttrs (
          finalAttrs: _: {
            version = "1.14.0";

            src = pkgs.fetchFromGitHub {
              owner = "SagerNet";
              repo = "sing-box";
              tag = "v${finalAttrs.version}";
              hash = "sha256-1v9bgM2H439ZoSkomv5dmT5SNrkuyOJ1iFFPlYPsW/k=";
            };

            vendorHash = "sha256-Bl73SkmnOyh5kULctDaxcOzXsYXRY2DOt80ME2+lBJo=";

            tags = [
              "with_gvisor"
              "with_quic"
              "with_dhcp"
              "with_wireguard"
              "with_utls"
              "with_acme"
              "with_clash_api"
              "with_tailscale"
              "with_ccm"
              "with_ocm"
              "with_cloudflared"
              "with_usbip"
              "with_openvpn"
              "with_openconnect"
              "badlinkname"
              "tfogo_checklinkname0"
            ];

            ldflags = [
              "-X=github.com/sagernet/sing-box/constant.Version=${finalAttrs.version}"
              "-X=runtime.godebugDefault=multipathtcp=0,tlssha1=1"
              "-checklinkname=0"
            ];
          }
        );
      };
    };
}
