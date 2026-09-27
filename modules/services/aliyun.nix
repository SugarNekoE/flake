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
      aliyun-assist = pkgs.buildGoModule {
        pname = "aliyun-assist-client";
        version = "unstable";

        src = inputs.aliyun-assist-client;

        vendorHash = null;

        subPackages = [ "." ];

        ldflags = [
          "-s"
          "-w"
        ];

        postInstall = ''
          mv $out/bin/aliyun_assist_client $out/bin/aliyun-service
        '';

        meta = {
          description = "Alibaba Cloud Assist client";
          homepage = "https://github.com/aliyun/aliyun_assist_client";
          license = pkgs.lib.licenses.asl20;
          mainProgram = "aliyun-service";
        };
      };
      cloudmonitor-agent = pkgs.stdenv.mkDerivation {
        pname = "aliyun-cloudmonitor-agent";
        version = "3.5.12";

        src = pkgs.fetchurl {
          url = "https://cloudmonitor-agent.oss-cn-hangzhou.aliyuncs.com/Argus/3.5.12/cloudmonitor_linux64.tar.gz";
          hash = "sha256-WTrzXS5dpwbr1QZyhhPiR3WoPeoETUsmD7mh4hKdri4=";
        };

        installPhase = ''
          mkdir -p $out/lib/cloudmonitor
          mkdir -p $out/bin
          cp -r * $out/lib/cloudmonitor/
          chmod +x $out/lib/cloudmonitor/bin/* || true
          chmod +x $out/lib/cloudmonitor/*.sh || true
          ln -s $out/lib/cloudmonitor/bin/argusagent \
            $out/bin/argusagent
          ln -s $out/lib/cloudmonitor/cloudmonitorCtl.sh \
            $out/bin/cloudmonitorctl
        '';

        postPatch = ''
          substituteInPlace cloudmonitorCtl.sh \
            --replace-fail \
            "/usr/local/cloudmonitor" \
            "\$out/lib/cloudmonitor"
        '';
      };
    in
    {
      environment.systemPackages = [
        aliyun-assist
        cloudmonitor-agent
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

      systemd.services.cloudmonitor-agent = {
        description = "Alibaba CloudMonitor Agent";
        wantedBy = [
          "multi-user.target"
        ];
        after = [
          "network-online.target"
        ];
        wants = [
          "network-online.target"
        ];
        serviceConfig = {
          Type = "forking";
          User = "root";
          StateDirectory = "cloudmonitor";
          LogsDirectory = "cloudmonitor";
          WorkingDirectory = "/var/lib/cloudmonitor";
          ExecStartPre = pkgs.writeShellScript "cloudmonitor-init" ''
            if [ ! -e /var/lib/cloudmonitor/bin ]; then
              ln -s \
                ${cloudmonitor-agent}/lib/cloudmonitor/bin \
                /var/lib/cloudmonitor/bin
            fi
            if [ ! -d /var/lib/cloudmonitor/conf ]; then
                cp -r \
                  ${cloudmonitor-agent}/lib/cloudmonitor/conf \
                  /var/lib/cloudmonitor/
              fi
          '';
          ExecStart = "${cloudmonitor-agent}/bin/cloudmonitorctl start";
          ExecStop = "${cloudmonitor-agent}/bin/cloudmonitorctl stop";
          Restart = "always";
          RestartSec = 10;
        };
      };
    };
}
