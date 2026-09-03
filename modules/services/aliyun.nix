{
  flake-file.inputs = {
    aliyun-assist-client = {
      url = "github:aliyun/aliyun_assist_client/release";
      flake = false;
    };
  };

  nixos =
    { pkgs, inputs, ... }:
    let
      aliyun-assist = pkgs.stdenv.mkDerivation {
        pname = "aliyun-assist-client";
        version = "unstable";

        src = inputs.aliyun-assist-client;

        nativeBuildInputs = [
          pkgs.go
        ];

        buildPhase = ''
          runHook preBuild

          export HOME=$TMPDIR
          export GOCACHE=$TMPDIR/go-cache

          go build \
            -mod=vendor \
            -trimpath \
            -o aliyun-service \
            .

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -Dm755 aliyun-service $out/bin/aliyun-service

          runHook postInstall
        '';
      };
    in
    {
      environment.systemPackages = [
        aliyun-assist
      ];

      systemd.tmpfiles.rules = [
        "d /usr/local/share/aliyun-assist 0755 root root -"
      ];

      systemd.services.aliyun = {
        description = "Aliyun Assist";

        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "cloud-final.service"
        ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";

          ExecStart = "${aliyun-assist}/bin/aliyun-service";

          Restart = "always";
          RestartSec = 5;

          User = "root";
        };
      };
    };
}
