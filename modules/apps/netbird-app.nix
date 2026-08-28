_:
let
  profiles = {
    home = {
      displayName = "Home";
      managementUrl = "https://connect.sne.moe:443";
    };
    atme = {
      displayName = "Atme";
      managementUrl = "https://connect.techinteaching.cn:443";
    };
  };
in
{
  nixos =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      client = lib.getExe pkgs.unstable.netbird;
      ensureProfiles = pkgs.writeShellApplication {
        name = "netbird-ensure-profiles";
        runtimeInputs = [ pkgs.gnugrep ];
        text = ''
          for attempt in {1..30}; do
            if profiles="$(${client} profile list 2>/dev/null)"; then
              break
            fi
            sleep 1
          done

          if [[ -z "''${profiles:-}" ]]; then
            echo "unable to read NetBird profiles" >&2
            exit 1
          fi

          for profile in ${lib.escapeShellArgs (builtins.attrNames profiles)}; do
            if ! grep -qE "^$profile[[:space:]]" <<<"$profiles"; then
              ${client} profile add "$profile"
            fi
          done
        '';
      };
    in
    {
      services.resolved.enable = true;

      services.netbird = {
        package = pkgs.unstable.netbird;
        ui.enable = false;

        clients.default = {
          name = "netbird";
          interface = "wt0";
          port = 51820;
          ui.enable = false;
          openFirewall = true;
          openInternalFirewall = true;
        };
      };

      users.users.${user.username}.extraGroups = [
        config.services.netbird.clients.default.user.group
      ];

      systemd.services.netbird-profiles = {
        description = "Ensure configured NetBird profiles exist";
        after = [ "netbird.service" ];
        requires = [ "netbird.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe ensureProfiles;
          RemainAfterExit = true;
        };
      };
    };

  home =
    { lib, pkgs, ... }:
    let
      client = lib.getExe pkgs.unstable.netbird;
      uiPackage = pkgs.unstable.netbird-ui;
      ui = lib.getExe uiPackage;
      icon = "${uiPackage}/share/icons/hicolor/256x256/apps/netbird.png";
    in
    {
      home.packages = [ uiPackage ];

      xdg.desktopEntries.netbird = {
        name = "NetBird";
        genericName = "Mesh VPN";
        comment = "Connect to and switch between NetBird profiles";
        exec = "${lib.getExe' pkgs.coreutils "env"} WEBKIT_DISABLE_DMABUF_RENDERER=1 ${ui}";
        inherit icon;
        terminal = false;
        categories = [ "Network" ];
        startupNotify = false;
        settings = {
          Keywords = "netbird;vpn;home;atme;";
          StartupWMClass = "org.wails.netbird";
        };
        actions = lib.mapAttrs (name: profile: {
          name = "Set up or switch to ${profile.displayName}";
          exec = "${client} up --profile ${name} --management-url ${profile.managementUrl}";
          inherit icon;
        }) profiles;
      };
    };
}
