{ config, inputs, ... }:
{
  user = config.userProfiles.sugar;
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    base
    sway
    desktop
    efi
    igpu
    sugar
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-luks;
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
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usbhid"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/nvme0n1";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
