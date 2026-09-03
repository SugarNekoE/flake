{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    efi
    i18n

    # roles
    base
    server

    # services
    podman
    mcsmanager
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    {
      identity,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        zip
        unzip
      ];

      nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];

      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.create ];

      networking.firewall.enable = lib.mkForce false;

      environment.etc."containers/registries.conf".source = lib.mkForce (
        pkgs.writeText "registries.conf" ''
          unqualified-search-registries = ["docker.io"]

          [[registry]]
          prefix = "docker.io"
          location = "docker.io"

          [[registry.mirror]]
          location = "dockerproxy.net"

          [[registry.mirror]]
          location = "docker.m.daocloud.io"
        ''
      );

      system.autoUpgrade = {
        enable = true;
        upgrade = true;
        operation = "switch";
        flake = "git+https://forge.asnk.io/sugar/flake";
        dates = "4:00";
        flags = [
          "--refresh"
        ];
      };

      boot.kernel.sysctl = lib.mkForce {
        "vm.swappiness" = "0";
        "kernel.sysrq" = "1";
        "net.ipv4.neigh.default.gc_stale_time" = "120";
        "net.ipv4.conf.all.rp_filter" = "0";
        "net.ipv4.conf.default.rp_filter" = "0";
        "net.ipv4.conf.default.arp_announce" = "2";
        "net.ipv4.conf.lo.arp_announce" = "2";
        "net.ipv4.conf.all.arp_announce" = "2";
        "net.ipv4.tcp_max_tw_buckets" = "5000";
        "net.ipv4.tcp_syncookies" = "1";
        "net.ipv4.tcp_max_syn_backlog" = "1024";
        "net.ipv4.tcp_synack_retries" = "2";
        "net.ipv4.tcp_slow_start_after_idle" = "0";
      };
    };
  hardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:

    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
      ];

      disko.devices.disk.system.device = "/dev/vda";

      services = {
        cloud-init = {
          enable = true;
          network.enable = true;
          settings = {
            preserve_hostname = false;
            growpart = {
              mode = "auto";
              devices = [ "/" ];
            };
            resize_rootfs = true;
          };
        };
        qemuGuest.enable = true;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
