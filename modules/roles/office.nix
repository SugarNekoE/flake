{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    thunderbird
    (flatpak.withPackages [
      "cn.wps.wps_365"
      "org.libreoffice.LibreOffice"
      "com.baidu.NetDisk"
      "md.obsidian.Obsidian"
      "com.todoist.Todoist"
      "net.xmind.XMind"
      "org.gimp.GIMP"
      "org.kde.krita"
    ])
  ];
}
