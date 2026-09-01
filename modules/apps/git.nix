_: {
  nixos =
    { config, user, ... }:
    {
      programs.git.enable = true;

      sops.secrets.gmail-app-password = {
        sopsFile = ../secrets/gmail-app.yaml;
        format = "yaml";
        key = "password";
      };

      sops.templates."git-smtp.ini" = {
        owner = user.username;
        mode = "0400";
        content = ''
          [sendemail "gmail"]
              smtpPass = ${config.sops.placeholder.gmail-app-password}
        '';
      };
    };
  home =
    {
      identity,
      lib,
      nixosConfig,
      pkgs,
      user,
      ...
    }:
    let
      signingKey = identity.gpgKeys.${user.git.signingKey} or null;
    in
    {
      assertions = [
        {
          assertion = signingKey != null;
          message = "user `${user.username}` selects unknown GPG identity `${user.git.signingKey}`";
        }
      ];

      home.packages = with pkgs; [
        git-lfs
      ];

      programs.git = {
        enable = true;
        includes = [
          { path = nixosConfig.sops.templates."git-smtp.ini".path; }
        ];
        signing = lib.mkIf (signingKey != null) {
          key = signingKey.fingerprint;
          signByDefault = true;
          signer = lib.getExe pkgs.gnupg;
        };
        settings = {
          core = {
            editor = "nvim";
            autocrlf = "input";
            preloadindex = true;
            fscache = true;
          };
          user = {
            name = user.fullName;
            inherit (user) email;
          };
          sendemail.gmail = {
            smtpServer = "smtp.gmail.com";
            smtpServerPort = 465;
            smtpEncryption = "ssl";
            smtpUser = user.email;
          };
          b4 = {
            sendemail-identity = "gmail";
            send-no-patatt-sign = false;
            send-endpoint-web = "https://lkml.kernel.org/_b4_submit";
          };
          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };
          init.defaultBranch = "main";
          color.ui = "auto";
          credential.helper = "store";
        };
      };
    };
}
