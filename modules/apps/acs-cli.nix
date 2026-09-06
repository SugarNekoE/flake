{ inputs, lib, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  home =
    { pkgs, ... }:
    {
      home.packages = [ inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.acs ];
    };

  perSystem =
    { config, pkgs, ... }:
    let
      buildImage =
        args:
        import ../../acs-k8s/nix/runner-image.nix (
          {
            inherit pkgs lib;
            acs = config.packages.acs;
          }
          // args
        );
    in
    {
      packages.acs = pkgs.buildGoModule {
        pname = "acs";
        version = "0.1.0";
        src = ../../acs-k8s/cli;
        vendorHash = "sha256-MYHY7N+LqNnfNuIdUqtb4Cr24UQqi+4tbc1ysdzJ2BY=";
        subPackages = [ "cmd/acs" ];
        env.CGO_ENABLED = "0";
        dontPatchELF = true;
        nativeCheckInputs = [
          pkgs.errcheck
          pkgs.kubernetes-helm
        ];
        checkPhase = ''
          runHook preCheck
          go test ./...
          go vet ./...
          errcheck -blank -excludeonly ./...
          runHook postCheck
        '';
        ldflags = [
          "-s"
          "-w"
        ];
        meta = {
          description = "ACS Forgejo runner operations and isolated Kind testing";
          mainProgram = "acs";
          platforms = lib.platforms.linux;
        };
      };
      apps.acs = {
        type = "app";
        program = lib.getExe config.packages.acs;
      };
      packages.acs-runner-nix-image = buildImage {
        name = "forgejo-runner-nix";
        nixSupport = true;
      };
      packages.acs-runner-go-image = buildImage {
        name = "forgejo-runner-go";
        extraPackages = [ pkgs.go ];
      };
      packages.acs-runner-node24-image = buildImage {
        name = "forgejo-runner-node24";
      };
      packages.acs-runner-docker-image = buildImage {
        name = "forgejo-runner-docker";
        buildahSupport = true;
      };
    };
}
