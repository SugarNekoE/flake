let
  installPath = "/opt/mosdns";
in
{
  nixos = { pkgs, ... }: {
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
        workingDirectory = installPath;
        ExecStart = ''
          ${pkgs.mosdns}/bin/mosdns start \
            -c ${installPath}/config.yaml
        '';
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
