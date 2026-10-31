{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    efi
    i18n
    aliyun

    # roles
    base
    server

    # services
    magpie
    (tailscale.withAuthKey ../secrets/tailscale/sne-moe.yaml)
    (netbird.withSetupKey {
      sopsFile = ../secrets/netbird/atme.yaml;
      managementUrl = "https://connect.techinteaching.cn:443";
      name = "atme";
      port = 51820;
    })
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    { pkgs, lib, ... }:
    {
      nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];

      environment.etc."containers/registries.conf".source = lib.mkForce (
        pkgs.writeText "registries.conf" ''
          unqualified-search-registries = ["docker.io"]

          [[registry]]
          prefix = "docker.io"
          location = "docker.io"

          [[registry.mirror]]
          location = "docker.1ms.run"

          [[registry.mirror]]
          location = "docker.m.daocloud.io"

          [[registry.mirror]]
          location = "dockerproxy.net"
        ''
      );

      services.tailscale.extraSetFlags = [ "--relay-server-port=40000" ];
    };
}
