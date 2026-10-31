{ inputs, ... }:
{
  flake-file.inputs.ops-agent = {
    url = "git+https://github.com/GoogleCloudPlatform/ops-agent?submodules=1";
    flake = false;
  };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.gcp-ops-agent;
      yaml = pkgs.formats.yaml { };

      version = "2.74.0";
      otelVersion = "v0.162.0";
      go = pkgs.go_1_26;
      buildGoModule = pkgs.buildGoModule.override { inherit go; };

      engine = buildGoModule {
        pname = "ops-agent-engine";
        inherit version;
        src = inputs.ops-agent;
        subPackages = [
          "cmd/google_cloud_ops_agent_engine"
          "cmd/agent_wrapper"
        ];
        vendorHash = "sha256-7MICaAw9sBW8pk2eUibpAEK0xJCNDNfvXDR+dM1d8uc=";
        env.CGO_ENABLED = "0";
        ldflags = [
          "-s"
          "-w"
          "-X github.com/GoogleCloudPlatform/ops-agent/internal/version.Version=${version}"
          "-X github.com/GoogleCloudPlatform/ops-agent/internal/version.BuildDistro=nixos"
        ];
      };

      fluent-bit = pkgs.fluent-bit.overrideAttrs (old: {
        version = "4.2.1";
        src = "${inputs.ops-agent}/submodules/fluent-bit";
        doInstallCheck = false;
        cmakeFlags = old.cmakeFlags ++ [
          "-DFLB_HTTP_SERVER=ON"
          "-DFLB_DEBUG=OFF"
          "-DFLB_SHARED_LIB=OFF"
          "-DFLB_STREAM_PROCESSOR=OFF"
          "-DFLB_KAFKA=OFF"
          "-DFLB_WASM=OFF"
          "-DFLB_CONFIG_YAML=OFF"
          "-DFLB_IN_SYSTEMD=On"
          "-DFLB_MSGPACK_TO_JSON_INIT_BUFFER_SIZE=1.5"
          "-DFLB_MSGPACK_TO_JSON_REALLOC_BUFFER_SIZE=.10"
        ];
      });

      collectorSource = pkgs.stdenvNoCC.mkDerivation {
        name = "otelopscol-source";
        src = "${inputs.ops-agent}/submodules/opentelemetry-operations-collector";
        nativeBuildInputs = [
          go
          pkgs.cacert
          pkgs.git
        ];
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-MmDbebiKacjciVZbCNOUOMf06GrFxjz1F/Vgt5Fv8zI=";
        dontFixup = true;
        buildPhase = ''
          export HOME=$TMPDIR GOPATH=$TMPDIR/go GOFLAGS=-modcacherw GOWORK=off GOTOOLCHAIN=local
          export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          GOBIN=$TMPDIR/bin CGO_ENABLED=0 go install go.opentelemetry.io/collector/cmd/builder@${otelVersion}
          cd otelopscol
          $TMPDIR/bin/builder --skip-compilation --config manifest.yaml
          (cd _build && go mod vendor)
        '';
        installPhase = ''
          cd ..
          cp -r . $out
        '';
      };

      otelopscol = pkgs.stdenv.mkDerivation {
        pname = "otelopscol";
        version = "0.162.1";
        src = collectorSource;
        nativeBuildInputs = [ go ];
        buildPhase = ''
          export HOME=$TMPDIR GOFLAGS=-mod=vendor GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=1
          cd otelopscol/_build
          go build -buildvcs=false -trimpath -ldflags "-s -w" \
            -tags remove_all_sd,enable_gce_sd,enable_kubernetes_sd -o otelopscol .
        '';
        installPhase = ''
          install -Dm755 otelopscol $out/bin/otelopscol
        '';
      };

      configFile = "/etc/google-cloud-ops-agent/config.yaml";
      engineBin = "${engine}/bin/google_cloud_ops_agent_engine";
      logsDirectory = "/var/log/google-cloud-ops-agent";

      subagent = name: stateName: {
        partOf = [ "google-cloud-ops-agent.service" ];
        after = [
          "network-online.target"
          "google-cloud-ops-agent.service"
        ];
        requires = [ "network-online.target" ];
        wantedBy = [ "google-cloud-ops-agent.service" ];
        restartTriggers = [ config.environment.etc.${lib.removePrefix "/etc/" configFile}.source ];
        environment = {
          RUNTIME_DIRECTORY = "/run/google-cloud-ops-agent-${name}";
          STATE_DIRECTORY = "/var/lib/google-cloud-ops-agent/${stateName}";
          LOGS_DIRECTORY = logsDirectory;
        };
        serviceConfig = {
          RuntimeDirectory = "google-cloud-ops-agent-${name}";
          RuntimeDirectoryPreserve = "yes";
          StateDirectory = "google-cloud-ops-agent/${stateName}";
          LogsDirectory = "google-cloud-ops-agent";
          Restart = "always";
        };
      };
    in
    {
      options.services.gcp-ops-agent = {
        settings = lib.mkOption {
          inherit (yaml) type;
          default = { };
          description = "Contents of /etc/google-cloud-ops-agent/config.yaml.";
        };
      };

      config = {
        environment.etc."google-cloud-ops-agent/config.yaml".source =
          yaml.generate "ops-agent-config.yaml" cfg.settings;

        systemd.services = {
          google-cloud-ops-agent = {
            description = "Google Cloud Ops Agent";
            wantedBy = [ "multi-user.target" ];
            wants = [
              "google-cloud-ops-agent-fluent-bit.service"
              "google-cloud-ops-agent-opentelemetry-collector.service"
              "network-online.target"
            ];
            after = [ "network-online.target" ];
            restartTriggers = [ config.environment.etc."google-cloud-ops-agent/config.yaml".source ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStartPre = "${engineBin} -in ${configFile}";
              ExecStart = "${pkgs.coreutils}/bin/true";
            };
          };

          google-cloud-ops-agent-fluent-bit =
            let
              base = subagent "fluent-bit" "fluent-bit";
            in
            base
            // {
              description = "Google Cloud Ops Agent - Logging Agent";
              serviceConfig = base.serviceConfig // {
                Type = "simple";
                ExecStartPre = "${engineBin} -service=fluentbit -in ${configFile} -logs ${logsDirectory} -state /var/lib/google-cloud-ops-agent/fluent-bit";
                ExecStart = lib.concatStringsSep " " [
                  "${engine}/bin/agent_wrapper"
                  "-config_path ${configFile}"
                  "-log_path ${logsDirectory}/subagents/logging-module.log"
                  "${fluent-bit}/bin/fluent-bit"
                  "--config /run/google-cloud-ops-agent-fluent-bit/fluent_bit_main.conf"
                  "--parser /run/google-cloud-ops-agent-fluent-bit/fluent_bit_parser.conf"
                  "--storage_path /var/lib/google-cloud-ops-agent/fluent-bit/buffers"
                ];
              };
            };

          google-cloud-ops-agent-opentelemetry-collector =
            let
              base = subagent "opentelemetry-collector" "opentelemetry-collector";
            in
            base
            // {
              description = "Google Cloud Ops Agent - Metrics Agent";
              serviceConfig = base.serviceConfig // {
                Type = "simple";
                ExecStartPre = "${engineBin} -service=otel -in ${configFile} -logs ${logsDirectory} -state /var/lib/google-cloud-ops-agent/opentelemetry-collector";
                ExecStart = "${otelopscol}/bin/otelopscol --config=/run/google-cloud-ops-agent-opentelemetry-collector/otel.yaml";
              };
            };
        };
      };
    };
}
