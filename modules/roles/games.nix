{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    hmcl
    (flatpak.withPackages [
      "com.valvesoftware.Steam"
      "com.valvesoftware.Steam.CompatibilityTool.Proton-GE"
      "com.vysp3r.ProtonPlus"
      "io.github.Foldex.AdwSteamGtk"
      "net.lutris.Lutris"
      "moe.launcher.the-honkers-railway-launcher"
      "sh.ppy.osu"
    ])
  ];

  nixos = { pkgs, ... }: {
    services.udev.packages = with pkgs; [
      game-devices-udev-rules
    ];
    hardware.uinput.enable = true;
    hardware.steam-hardware.enable = true;
  };

  home = { pkgs, ... }: {
    home.packages = with pkgs; [
      zulu21
    ];
  };
}
