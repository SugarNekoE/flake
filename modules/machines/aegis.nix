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
    aliyun
    podman
    uptimekuma
    (cloudflared.withSecret ../secrets/cloudflared/aegis.yaml)
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
      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.aegis ];

      networking.firewall.enable = lib.mkForce false;
      networking.hosts."172.31.129.10" = [ "forge.asnk.io" ];

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
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot.initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
      ];

      disko.devices.disk.system.device = "/dev/vda";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
