_:
let
  sopsFile = ../secrets/gpg.yaml;
  hasPrivateKeys = builtins.pathExists sopsFile;
  secretName = name: "gpg-${name}-private-key";
  secretPath = name: "/run/secrets/${secretName name}";
in
{
  nixos =
    {
      identity,
      lib,
      user,
      ...
    }:
    {
      sops.secrets = lib.mkIf hasPrivateKeys (
        lib.mapAttrs' (
          name: _keyPair:
          lib.nameValuePair (secretName name) {
            inherit sopsFile;
            key = "gpg/privateKeys/${name}";
            owner = user.username;
            mode = "0400";
          }
        ) identity.gpgKeys
      );
    };

  home =
    {
      lib,
      pkgs,
      identity,
      ...
    }:
    let
      keyPairs = identity.gpgKeys;
      importPrivateKeys = pkgs.writeShellScript "gpg-import-private-keys" (
        ''
          set -eu
        ''
        + lib.concatMapStringsSep "\n" (name: ''
          ${lib.getExe pkgs.gawk} 'NR == 1 { print; print ""; next } { print }' \
            ${lib.escapeShellArg (secretPath name)} \
            | ${lib.getExe pkgs.gnupg} --batch --import
        '') (builtins.attrNames keyPairs)
      );
    in
    {
      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        maxCacheTtl = 7200;
        pinentry.package = pkgs.pinentry-gnome3;
      };

      systemd.user.services.gpg-import-private-keys = lib.mkIf hasPrivateKeys {
        Unit = {
          Description = "Import SOPS-managed GPG private keys";
        };

        Service = {
          Type = "oneshot";
          ExecStart = importPrivateKeys;
          RemainAfterExit = true;
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
