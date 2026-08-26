{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "cn.wps.wps_365"
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
        libreoffice
        thunderbird
      ];
    };
}
