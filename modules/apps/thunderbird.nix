_: {
  home =
    {
      identity,
      pkgs,
      ...
    }:
    let
      mainGpgKeyId = builtins.substring 24 16 identity.gpgKeys.main.fingerprint;
      external-editor-revived-host = pkgs.external-editor-revived;
      external-editor-revived = pkgs.stdenvNoCC.mkDerivation {
        pname = "external-editor-revived-addon";
        inherit (external-editor-revived-host) version;

        src = pkgs.fetchFromGitHub {
          owner = "Frederick888";
          repo = "external-editor-revived";
          tag = "v${external-editor-revived-host.version}";
          hash = "sha256-K5agRpFJ8iqvPnx3IIMTvrkObT/GB962EtdvWf7Eq4w=";
        };

        nativeBuildInputs = [ pkgs.zip ];

        postPatch = ''
          substituteInPlace extension/background.js \
            --replace-fail $'\nnativeMessagingPing()\n' \
            $'\nbrowser.storage.local.set({ editor: "nvim", terminal: "kitty", shell: "sh", template: "kitty --start-as=normal --override=macos_quit_when_last_window_closed=yes -- nvim /path/to/temp.eml" }).then(nativeMessagingPing)\n'
        '';

        installPhase = ''
          runHook preInstall

          install -d "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
          (cd extension && zip -r "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/external-editor-revived@tsundere.moe.xpi" .)

          runHook postInstall
        '';
      };
    in
    {
      home.packages = [ external-editor-revived-host ];

      programs.thunderbird = {
        enable = true;
        nativeMessagingHosts = [ external-editor-revived-host ];
        profiles.default = {
          isDefault = true;
          extensions = [ external-editor-revived ];
          settings = {
            "extensions.autoDisableScopes" = 0;
            "mail.default_send_format" = 1;
            "mail.identity.default.auto_quote" = true;
            "mail.identity.default.compose_html" = false;
            "mail.identity.default.is_gnupg_key_id" = true;
            "mail.identity.default.openpgp_key_id" = mainGpgKeyId;
            "mail.identity.default.reply_on_top" = 0;
            "mail.identity.default.sig_on_fwd" = true;
            "mail.identity.default.sig_on_reply" = true;
            "mail.identity.default.sign_mail" = true;
            "mail.openpgp.allow_external_gnupg" = true;
            "mailnews.send_plaintext_flowed" = false;
            "mailnews.wraplength" = 0;
            "xpinstall.signatures.required" = false;
          };
        };
      };
    };
}
