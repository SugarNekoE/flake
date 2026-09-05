_: {
  nixos = { pkgs, ... }: {
    boot = {
      plymouth = {
        enable = true;
        theme = "nixos-mac-style";
        themePackages = [
          (pkgs.stdenv.mkDerivation {
            name = "plymouth-theme-nixos-mac-style";
            version = "1.0";
            src = ../../plymouth/nixos-mac-style;
            installPhase = ''
              mkdir -p $out/share/plymouth/themes/nixos-mac-style
              cp -r . $out/share/plymouth/themes/nixos-mac-style/
            '';
          })
        ];
      };
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "udev.log_level=3"
        "rd.udev.log_level=3"
        "rd.systemd.show_status=false"
      ];
    };
  };
}
