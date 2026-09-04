{ pkgs, ... }:
let
  installPath = "/opt/mosdns";
in
{
  systemd.tmpfiles.rules = [
    "d ${installPath} 0750 root root -"
  ];

  systemd.services.mosdns = {
    description = "MosDNS DNS Forwarder";
    wantedBy = [
      "multi-user.target"
    ];
    after = [
      "network-online.target"
    ];
    wants = [
      "network-online.target"
    ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.mosdns}/bin/mosdns start \
          -c ${installPath}/config.yaml
      '';
      Restart = "on-failure";
      RestartSec = 5;
      User = "mosdns";
      Group = "mosdns";
      StateDirectory = "mosdns";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  users.users.mosdns = {
    isSystemUser = true;
    group = "mosdns";
  };

  users.groups.mosdns = { };
}
