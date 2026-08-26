_: {
  nixos =
    { lib, ... }:
    {
      services.displayManager.ly = {
        enable = true;
        settings = {
          tty = lib.mkForce 2;
        };
      };

      systemd.services.display-manager = {
        conflicts = lib.mkForce [
          "autovt@tty2.service"
        ];

        after = lib.mkForce [
          "acpid.service"
          "systemd-logind.service"
          "systemd-user-sessions.service"
          "plymouth-quit-wait.service"
          "autovt@tty2.service"
        ];
      };
    };
}
