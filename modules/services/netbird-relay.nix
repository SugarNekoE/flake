let
  installPath = "/opt/netbird";
in
{
  nixos = {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        netbird-relay = {
          image = "docker.io/netbirdio/relay:latest";
          ports = [
            "8443:8443"
            "3478:3478/udp"
          ];
          environmentFiles = [
            "${installPath}/relay.env"
          ];
          volumes = [
            "${installPath}/data:/data"
            "${installPath}/certs:/certs"
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "f ${installPath}/data 0750 root root -"
      "d ${installPath}/certs 0750 root root -"
    ];
  };
}
