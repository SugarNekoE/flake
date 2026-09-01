{ inputs, ... }: {
  imports = with inputs.self.aspects; [
    openssh
    podman
    networkmanager.nixos
  ];

  nixos = {
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = "1";
      "net.ipv6.conf.all.forwarding" = "1";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv6.tcp_congestion_control" = "bbr";
    };

    systemd = {
      enableEmergencyMode = false;
      settings.Manager = {
        RuntimeWatchdogSec = "20s";
        RebootWatchdogSec = "30s";
        KExecWatchdogSec = "1m";
      };
    };

    documentation = {
      man.enable = false;
      dev.enable = false;
      doc.enable = false;
      nixos.enable = false;
    };

    fonts.fontconfig.enable = false;

    programs.git.enable = true;
    programs.vim = {
      enable = true;
      defaultEditor = true;
    };

    users.mutableUsers = false;

    networking.firewall = {
      enable = true;
      backend = "firewalld";
    };
  };
}
