{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.slack.Slack"
    ])
  ];
  home =
    { lib, pkgs, ... }:
    let
      wemeetPackage = pkgs.unstable.wemeet;
      wemeetNativeWayland = pkgs.runCommand "wemeet-native-wayland" { } ''
        mkdir -p $out/bin

        grep -q wemeet-wayland-screenshare ${lib.getExe wemeetPackage}
        sed \
          -e '/wemeet-wayland-screenshare/d' \
          -e '/^exec /i export QT_QPA_PLATFORM=wayland' \
          ${lib.getExe wemeetPackage} > $out/bin/wemeet-native-wayland
        chmod +x $out/bin/wemeet-native-wayland

        ! grep -q wemeet-wayland-screenshare $out/bin/wemeet-native-wayland
      '';
    in
    {
      home.packages = with pkgs; [
        figma-linux
        feishu
        wemeetPackage
        wemeetNativeWayland
      ];

      xdg.desktopEntries = {
        wemeetapp = {
          name = "Tencent Meeting";
          comment = "Tencent Meeting with native Wayland screen sharing";
          exec = "${wemeetNativeWayland}/bin/wemeet-native-wayland %u";
          icon = "wemeet";
          terminal = false;
          categories = [ "AudioVideo" ];
          mimeType = [ "x-scheme-handler/wemeet" ];
        };

        wemeet-xwayland = {
          name = "Tencent Meeting (XWayland fallback)";
          comment = "Tencent Meeting with the legacy portal screen-sharing hook";
          exec = "${lib.getExe' wemeetPackage "wemeet-xwayland"} %u";
          icon = "wemeet";
          terminal = false;
          categories = [ "AudioVideo" ];
        };
      };
    };
}
