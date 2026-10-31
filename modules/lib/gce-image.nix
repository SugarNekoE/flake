{ config, lib, ... }:
let
  gceModule =
    { lib, ... }:
    {
      disko = {
        devices.disk.system = {
          imageName = "disk";
          imageSize = lib.mkDefault "20G";
        };
        imageBuilder.imageFormat = "raw";
      };
    };

  buildGce = nixosConfiguration: nixosConfiguration.extendModules { modules = [ gceModule ]; };

  packageImage =
    nixosConfiguration:
    let
      inherit (nixosConfiguration) pkgs;
    in
    pkgs.runCommand "gce-image.tar.gz"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];
      }
      ''
        tar -Sc -C ${nixosConfiguration.config.system.build.diskoImages} disk.raw | gzip > $out
      '';
in
{
  flake = {
    lib.buildGce = buildGce;
    gceImages = lib.mapAttrs (
      _: nixosConfiguration: packageImage (buildGce nixosConfiguration)
    ) config.flake.nixosConfigurations;
  };
}
