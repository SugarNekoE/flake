_: {
  nixos = { pkgs, ... }: {
    stylix.targets.plymouth.enable = true;
    boot = {
      plymouth = {
        enable = true;
        theme = "nixos-mac-style";
        themePackages = [
          (pkgs.stdenv.mkDerivation {
            name = "plymouth-theme-nixos-mac-style";
            version = "1.0";
            src = ../../assets/plymouth/nixos-mac-style;
            installPhase = ''
              mkdir -p $out/share/plymouth/themes/nixos-mac-style
              cp -r . $out/share/plymouth/themes/nixos-mac-style/
              substituteInPlace "$out/share/plymouth/themes/nixos-mac-style/nixos-mac-style.plymouth" \
                --replace-fail /usr/share/plymouth "$out/share/plymouth"
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
