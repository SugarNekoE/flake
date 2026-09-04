{
  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mounts = config.mounts.nfs;
    in
    {
      options.mounts.nfs = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              remote = lib.mkOption {
                type = lib.types.str;
                example = "example.com:/";
              };

              version = lib.mkOption {
                type = lib.types.str;
                example = "v4";
              };

              minorVersion = lib.mkOption {
                type = lib.types.str;
                example = "0";
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
        environment.systemPackages = [ pkgs.nfs-utils ];

        fileSystems = lib.mapAttrs (_mountPoint: mount: {
          device = mount.remote;
          fsType = "nfs";
          options = [
            "_netdev"
            "nofail"
            "x-systemd.automount"
            "x-systemd.idle-timeout=60s"
            "x-systemd.mount-timeout=10s"
            "vers=${mount.version}"
            "minorversion=${mount.minorVersion}"
            "hard"
            "timeo=600"
            "retrans=2"
            "noresvport"
          ]
          ++ mount.extraOptions;
        }) mounts;
      };
    };
}
