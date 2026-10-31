{
  nixos =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    let
      root = config.disko.devices.disk.system.content.partitions.root;
    in
    {
      imports = [ (modulesPath + "/virtualisation/google-compute-config.nix") ];

      disko.devices.disk.system.device = "/dev/sda";

      fileSystems."/" = {
        device = lib.mkForce root.device;
        fsType = lib.mkForce root.content.format;
      };

      networking.firewall.enable = lib.mkForce false;
      networking.networkmanager.enable = lib.mkForce false;
      networking.useNetworkd = true;
      networking.useDHCP = false;
      networking.interfaces.eth0.useDHCP = true;
    };
}
