_: {
  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.hmcl;
      colors = config.lib.stylix.colors.withHashtag;
      brightness = if config.stylix.polarity == "either" then "auto" else config.stylix.polarity;
      font = config.stylix.fonts.sansSerif.name;
      themeSettings = {
        "$schema" = "https://schemas.glavo.site/hmcl/launcher-settings/1.0.0";
        themeAppearanceOverrides = [
          "themeBrightnessMode"
          "themeColor"
          "background"
        ];
        themeBrightnessMode = brightness;
        customThemeColor = colors.base0D;
        themeColorType = "CUSTOM";
        launcherFontFamily = font;
        logFontFamily = config.stylix.fonts.monospace.name;
        backgroundType = if cfg.wallpaper == null then "THEME_COLOR" else "NETWORK";
        networkBackgroundImageUrl = cfg.wallpaper;
        networkBackgroundImageCachePolicy = "ENABLED";
      };
      themeFile = pkgs.writeText "hmcl-stylix-theme.json" (builtins.toJSON themeSettings);
      applyTheme = pkgs.writeShellScript "hmcl-apply-stylix-theme" ''
        settings_dir="$HOME/.hmcl/config"
        settings_file="$settings_dir/launcher-settings.json"
        ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"

        if [ -f "$settings_file" ]; then
          temporary_file="$settings_file.stylix.tmp"
          if ${pkgs.jq}/bin/jq -s '
            .[0] as $current
            | .[1] as $managed
            | $current * $managed
            | .themeAppearanceOverrides = (
                ($current.themeAppearanceOverrides // [])
                + $managed.themeAppearanceOverrides
                | unique
              )
          ' "$settings_file" ${themeFile} > "$temporary_file"; then
            ${pkgs.coreutils}/bin/mv "$temporary_file" "$settings_file"
          else
            ${pkgs.coreutils}/bin/rm -f "$temporary_file"
          fi
        else
          ${pkgs.coreutils}/bin/install -m600 ${themeFile} "$settings_file"
        fi
      '';
      hmcl = pkgs.hmcl.overrideAttrs (oldAttrs: {
        postFixup = (oldAttrs.postFixup or "") + ''
          mv $out/bin/hmcl $out/bin/.hmcl-wrapped
          makeShellWrapper $out/bin/.hmcl-wrapped $out/bin/hmcl \
            --set HMCL_FONT ${lib.escapeShellArg font} \
            --run ${lib.escapeShellArg applyTheme}
        '';
      });
    in
    {
      options.programs.hmcl.wallpaper = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "https?://.+");
        default = null;
        example = "https://assets.sne.moe/Backgrounds/HMCL.jpg";
      };

      config.home.packages = [ hmcl ];
    };
}
