{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      tern-runtime = pkgs.callPackage ./_runtime.nix { };
      unfreePkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    lib.mkIf (system == "x86_64-linux") {
      packages = { inherit tern-runtime; };
      legacyPackages.tern = unfreePkgs.callPackage ./_package.nix { inherit tern-runtime; };
    };

  home =
    { config, ... }:
    let
      daemon = "${config.home.homeDirectory}/.nix-profile/libexec/tern/tern";
    in
    {
      systemd.user.services.tern-daemon = {
        Unit = {
          Description = "Tern session daemon";
          ConditionPathExists = daemon;
        };
        Service = {
          ExecStart = "${daemon} daemon";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
