{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "net.xmind.XMind"
      "org.gimp.GIMP"
      "org.kde.krita"
      "org.libreoffice.LibreOffice"
      "cn.wps.wps_365"
      "org.mozilla.thunderbird_esr"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        obsidian
        todoist
      ];
    };
}
