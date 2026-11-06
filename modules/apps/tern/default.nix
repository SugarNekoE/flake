{ inputs, lib, ... }:
{
  perSystem =
    { system, ... }:
    let
      unfreePkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    lib.mkIf (system == "x86_64-linux") {
      legacyPackages.tern = unfreePkgs.callPackage ./_package.nix { };
    };

  home =
    { config, ... }:
    let
      tern = "${config.home.homeDirectory}/.nix-profile/libexec/tern/tern";
    in
    {
      systemd.user.services.tern-remote = {
        Unit = {
          Description = "Tern remote sessions (this user)";
          ConditionPathExists = tern;
          StartLimitIntervalSec = 60;
          StartLimitBurst = 10;
        };
        Service = {
          Type = "exec";
          ExecStart = "${tern} remote serve --user --authorized-keys /etc/ssh/authorized_keys.d/${config.home.username}";
          Restart = "on-failure";
          RestartSec = 2;
          RestartPreventExitStatus = 2;
          KillMode = "process";
          TimeoutStopSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
