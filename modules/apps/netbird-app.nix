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
      cleanRootProfiles = pkgs.writeShellApplication {
        name = "netbird-clean-root-profiles";
        runtimeInputs = [ pkgs.gawk ];
        text = ''
          for _attempt in {1..30}; do
            if profile_list="$(${client} profile list --show-id 2>/dev/null)"; then
              break
            fi
            sleep 1
          done

          if [[ -z "''${profile_list:-}" ]]; then
            echo "unable to read root NetBird profiles" >&2
            exit 1
          fi

          default_seen=
          while read -r id name; do
            [[ -n "$id" && -n "$name" ]] || continue
            if [[ "$name" == default && -z "$default_seen" ]]; then
              default_seen=1
            else
              ${client} profile remove "$id"
            fi
          done < <(awk 'NR > 1 { print $1, $2 }' <<<"$profile_list")
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
        description = "Remove obsolete root NetBird profiles";
        after = [ "netbird.service" ];
        requires = [ "netbird.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe cleanRootProfiles;
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
      profileNames = builtins.attrNames profiles;
      reconcileProfiles = pkgs.writeShellApplication {
        name = "netbird-reconcile-profiles";
        runtimeInputs = [ pkgs.gawk ];
        text = ''
          for _attempt in {1..30}; do
            if profile_list="$(${client} profile list --show-id 2>/dev/null)"; then
              break
            fi
            sleep 1
          done

          if [[ -z "''${profile_list:-}" ]]; then
            echo "unable to read NetBird profiles" >&2
            exit 1
          fi

          declare -A seen=([default]=1)
          while read -r id name; do
            [[ -n "$id" && -n "$name" ]] || continue

            case "$name" in
              default)
                ;;
              ${lib.concatMapStringsSep "|" lib.escapeShellArg profileNames})
                if [[ -n "''${seen[$name]:-}" ]]; then
                  ${client} profile remove "$id"
                else
                  seen["$name"]=1
                fi
                ;;
              *)
                ${client} profile remove "$id"
                ;;
            esac
          done < <(awk 'NR > 1 { print $1, $2 }' <<<"$profile_list")

          for name in ${lib.escapeShellArgs profileNames}; do
            if [[ -z "''${seen[$name]:-}" ]]; then
              ${client} profile add "$name"
            fi
          done
        '';
      };
    in
    {
      home.packages = [ uiPackage ];

      systemd.user.services.netbird-profiles = {
        Unit.Description = "Reconcile configured NetBird profiles";
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe reconcileProfiles;
        };
      };

      xdg.desktopEntries.netbird = {
        name = "NetBird";
        genericName = "Mesh VPN";
        comment = "Connect to and switch between NetBird profiles";
        exec = "${lib.getExe' pkgs.coreutils "env"} WEBKIT_DISABLE_DMABUF_RENDERER=1 ${ui} --daemon-addr=unix:///run/netbird/sock";
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
