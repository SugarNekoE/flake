{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    efi
    i18n
    nfs
    aliyun

    # roles
    base
    server

    # services
    podman
    forgejo
    (tailscale.withAuthKey ../secrets/tailscale/sne-moe.yaml)
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos = {
    services.openssh.ports = [ 2222 ];

    mounts.nfs = {
      "/mnt/data" = {
        remote = "121wm2ey8pigiyqr6qw-xqr37.cn-hongkong.nas.aliyuncs.com:/";
        version = "4";
        minorVersion = "0";
        extraOptions = [
          "rsize=1048576"
          "wsize=1048576"
          "nconnect=16"
        ];
      };
    };
  };
}
