{ inputs, ... }:
{
  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "textfile"
        ];
        extraFlags = [
          "--collector.textfile.directory=${
            pkgs.writeTextDir "nixos.prom" (
              ''
                nixos_configuration_info{revision="${lib.defaultTo "unknown" config.system.configurationRevision}"} 1
              ''
              + lib.optionalString (inputs.self ? lastModified) ''
                nixos_configuration_last_modified_seconds ${toString inputs.self.lastModified}
              ''
            )
          }"
        ];
      };

      networking.firewall.allowedTCPPorts = [
        config.services.prometheus.exporters.node.port
      ];
    };
}
