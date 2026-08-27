{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "cn.wps.wps_365"
      "org.libreoffice.LibreOffice"
      "org.mozilla.thunderbird_esr"
      "com.baidu.NetDisk"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        obsidian
        todoist
        xmind
        gimp
        krita
      ];
    };
}
