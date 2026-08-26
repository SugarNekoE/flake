{ inputs, ... }:
let
  withCredentials =
    { sopsFile }:
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.cifs ];
      nixosModule =
        { lib, ... }:
        let
          hasCredentials = builtins.pathExists sopsFile;
        in
        {
          sops.secrets."cifs-credentials" = lib.mkIf hasCredentials {
            format = "yaml";
            inherit sopsFile;
            key = "cifs-credentials";
            mode = "0400";
          };
        };
    };
in
{
  aspectHelpers.cifs = { inherit withCredentials; };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mounts = config.mounts.cifs;
    in
    {
      options.mounts.cifs = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              remote = lib.mkOption {
                type = lib.types.str;
                example = "//nas/media";
              };

              credentialsFile = lib.mkOption {
                type = lib.types.str;
                description = "Runtime path to mount.cifs credentials.";
              };

              extraOptions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          }
        );
      };

      config = lib.mkIf (mounts != { }) {
        environment.systemPackages = [ pkgs.cifs-utils ];

        fileSystems = lib.mapAttrs (_mountPoint: mount: {
          device = mount.remote;
          fsType = "cifs";
          options = [
            "_netdev"
            "nofail"
            "x-systemd.automount"
            "x-systemd.idle-timeout=60s"
            "x-systemd.mount-timeout=10s"
            "credentials=${mount.credentialsFile}"
          ]
          ++ mount.extraOptions;
        }) mounts;
      };
    };
}
