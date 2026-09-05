_: {
  nixos = { pkgs, ... }: {
    virtualisation = {
      docker.enable = false;
      podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
    environment.systemPackages = with pkgs; [
      podman-compose
      docker-compose
    ];
  };
}
