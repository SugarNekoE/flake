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
      workingDirectory = installPath;
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
      };
    };
  };
}
