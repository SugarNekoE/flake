let
  installPath = "/var/lib/hermes";
in
{ inputs, ... }:
{
  flake-file.inputs.hermes-agent.url = "github:NousResearch/hermes-agent";

  nixos = { config, ... }: {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        hermes = {
          autoStart = true;
          image = "docker.io/nousresearch/hermes-agent:latest";
          cmd = [
            "gateway"
            "run"
          ];
          ports = [
            "8642:8642"
            "9119:9119"
          ];
          volumes = [
            "${installPath}:/opt/data"
          ];
          environment = {
            HERMES_DASHBOARD = "1";
          };
        };
      };
    };
  };

  home = { lib, ... }: {
    imports = [ inputs.hermes-agent.homeManagerModules.default ];

    programs.hermes-agent = {
      enable = true;
      desktop.enable = true;
    };
  };
}
