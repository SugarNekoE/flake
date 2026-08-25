{
  nixos =
    { config, lib, ... }:
    let
      mounts = config.mounts.xfs;
    in
    {
      options.mounts.xfs = lib.mkOption {
        default = { };
        description = "Already-formatted XFS data filesystems keyed by mountpoint.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              device = lib.mkOption {
                type = lib.types.str;
                example = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
                description = "Stable path to an existing XFS filesystem.";
              };

              extraOptions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "nofail" ];
                description = "Additional mount options appended after defaults and pquota.";
              };
            };
          }
        );
      };

      config = lib.mkIf (mounts != { }) {
        fileSystems = lib.mapAttrs (_mountPoint: mount: {
          inherit (mount) device;
          fsType = "xfs";
          options = [
            "defaults"
            "pquota"
          ]
          ++ mount.extraOptions;
        }) mounts;
      };
    };
}
