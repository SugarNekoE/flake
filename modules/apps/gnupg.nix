_: {
  home =
    {
      config,
      lib,
      pkgs,
      identity,
      ...
    }:
    let
      sopsFile = ../secrets/gpg.yaml;
      hasPrivateKeys = builtins.pathExists sopsFile;
      keyPairs = identity.gpgKeys;
      secretName = name: "gpg-${name}-private-key";
      secretPath = name: config.sops.secrets.${secretName name}.path;
      importPrivateKeys = pkgs.writeShellScript "gpg-import-private-keys" (
        ''
          set -eu
        ''
        + lib.concatMapStringsSep "\n" (name: ''
          ${lib.getExe pkgs.gnupg} --batch --import ${lib.escapeShellArg (secretPath name)}
        '') (builtins.attrNames keyPairs)
      );
    in
    {
      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        maxCacheTtl = 7200;
      };

      sops.secrets = lib.mkIf hasPrivateKeys (
        lib.mapAttrs' (
          name: keyPair:
          lib.nameValuePair (secretName name) {
            inherit sopsFile;
            key = keyPair.privateKey;
            mode = "0400";
          }
        ) keyPairs
      );

      systemd.user.services.gpg-import-private-keys = lib.mkIf hasPrivateKeys {
        Unit = {
          Description = "Import SOPS-managed GPG private keys";
          After = [ "sops-nix.service" ];
          Requires = [ "sops-nix.service" ];
          PartOf = [ "sops-nix.service" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = importPrivateKeys;
          RemainAfterExit = true;
        };

        Install.WantedBy = [ "default.target" ];
      };

      programs.git = {
        signing = {
          key = identity.gpgKeys.main.fingerprint;
          signByDefault = true;
          signer = lib.getExe pkgs.gnupg;
        };
      };
    };
}
