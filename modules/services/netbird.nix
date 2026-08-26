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
      sopsFile = ../secrets/netbird.yaml;
      hasSetupKeys = builtins.pathExists sopsFile;
      profiles = {
        home = {
          managementUrl = "https://connect.sne.moe:443";
        };
        atme = {
          managementUrl = "https://connect.techinteaching.cn:443";
        };
      };
      secretName = name: "netbird-setup-key-${name}";
      netbird = lib.getExe config.services.netbird.clients.default.wrapper;
    in
    {
      users.users.${user.username}.extraGroups = [ "netbird" ];

      sops.secrets = lib.mkIf hasSetupKeys (
        lib.mapAttrs' (
          name: _profile:
          lib.nameValuePair (secretName name) {
            inherit sopsFile;
            key = "netbird_setup_key/${name}";
            owner = user.username;
            mode = "0400";
            restartUnits = [ "netbird-profiles.service" ];
          }
        ) profiles
      );

      services.netbird = {
        package = pkgs.unstable.netbird;
        # The 26.05 module's UI wrapper expects the legacy desktop file. The
        # single standard socket does not need that multi-client wrapper.
        ui.enable = false;
        clients.default = {
          name = "netbird";
          interface = "wt0";
          port = 51820;
        };
      };

      environment.systemPackages = [ pkgs.unstable.netbird-ui ];

      systemd.services.netbird-profiles = lib.mkIf hasSetupKeys {
        description = "Initialize NetBird profiles";
        after = [
          "netbird.service"
          "sops-install-secrets.service"
        ];
        requires = [
          "netbird.service"
          "sops-install-secrets.service"
        ];
        wantedBy = [ "multi-user.target" ];

        path = [
          pkgs.coreutils
          pkgs.gawk
        ];
        serviceConfig = {
          Type = "oneshot";
          User = user.username;
          Group = "netbird";
          StateDirectory = "netbird-profiles";
        };

        script =
          let
            setupProfile = name: profile: ''
              setup_profile \
                ${lib.escapeShellArg name} \
                ${lib.escapeShellArg profile.managementUrl} \
                ${lib.escapeShellArg config.sops.secrets.${secretName name}.path}
            '';
          in
          ''
            set -euo pipefail

            has_profile() {
              ${netbird} profile list | awk -v profile="$1" \
                'NR > 1 && $1 == profile { found = 1 } END { exit !found }'
            }

            until ${netbird} profile list >/dev/null 2>&1; do
              sleep 1
            done

            if ! has_profile home; then
              ${netbird} profile rename default home
              rm -f "$STATE_DIRECTORY/home"
            fi

            if ! has_profile atme; then
              ${netbird} profile add atme
              rm -f "$STATE_DIRECTORY/atme"
            fi

            initialized=0

            setup_profile() {
              local name="$1"
              local management_url="$2"
              local setup_key_file="$3"
              local marker="$STATE_DIRECTORY/$name"

              if [[ ! -e "$marker" ]]; then
                ${netbird} up \
                  --profile "$name" \
                  --management-url "$management_url" \
                  --setup-key-file "$setup_key_file"
                touch "$marker"
                initialized=1
              fi
            }

            ${lib.concatStrings (lib.mapAttrsToList setupProfile profiles)}

            if (( initialized )); then
              ${netbird} profile select home
            fi
          '';
      };
    };
}
