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
    podman
    (pocket-id.withEnvFile ../secrets/pocket-id.env)
    (cloudflared.withSecret ../secrets/cloudflared/miko.yaml)
    (tailscale.withAuthKey ../secrets/tailscale/sne-moe.yaml)
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
}
