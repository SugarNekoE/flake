{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    bios
    i18n
    llm-agents

    # roles
    base
    server

    # services
    magpie
    (tailscale.withAuthKey {
      sopsFile = ../secrets/tailscale/sne-moe.yaml;
    })
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota-bios;
  nixos =
    {
      identity,
      lib,
      pkgs,
      ...
    }:
    {
      time.timeZone = lib.mkForce "Asia/Tokyo";
      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.sugar ];
      environment.systemPackages = with pkgs; [
        llm-agents.grok
        llm-agents.claude-code
        llm-agents.cursor-agent
      ];
      systemd.tmpfiles.rules = [
        "d /root/.grok/bin 0755 root root -"
        "L+ /root/.grok/bin/grok - - - - ${pkgs.llm-agents.grok}/bin/grok"
      ];
      networking.firewall.enable = lib.mkForce false;
      networking.networkmanager.enable = lib.mkForce false;
      networking.enableIPv6 = true;
      networking.useNetworkd = true;
      networking.useDHCP = false;
      systemd.network.links."10-eth0" = {
        matchConfig.MACAddress = "f4:0d:60:00:09:fc";
        linkConfig.Name = "eth0";
      };
      services = {
        cloud-init = {
          enable = true;
          network.enable = true;
          settings = {
            datasource_list = [ "NoCloud" ];
            preserve_hostname = false;
            growpart = {
              mode = "auto";
              devices = [ "/" ];
            };
            resize_rootfs = true;
          };
        };
        qemuGuest.enable = true;
        openssh.ports = [ 53222 ];
      };

    };
  hardware =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sr_mod"
        "virtio_blk"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/vda";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };

}
