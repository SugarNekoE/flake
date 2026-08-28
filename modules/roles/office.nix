{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "cn.wps.wps_365"
      "org.libreoffice.LibreOffice"
      "org.mozilla.thunderbird_esr"
      "com.baidu.NetDisk"
      "md.obsidian.Obsidian"
      "com.todoist.Todoist"
      "net.xmind.XMind"
      "org.gimp.GIMP"
      "org.kde.krita"
    ])
  ];
}
