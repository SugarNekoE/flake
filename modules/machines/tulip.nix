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
    mosdns
    (tailscale.withAuthKey ../secrets/tailscale/sne-moe.yaml)
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
}
