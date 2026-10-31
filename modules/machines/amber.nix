{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    efi
    i18n
    gce

    # roles
    base
    server

    # services
    gcp-ops-agent
    (cloud-sql-proxy.withInstance "PROJECT:REGION:INSTANCE")
    (niks3.withSecrets ../secrets/niks3/amber.yaml)
    (cloudflared.withSecret ../secrets/cloudflared/amber.yaml)
    (tailscale.withAuthKey ../secrets/tailscale/sne-moe.yaml)
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    { identity, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.sugar ];

      zramSwap.enable = true;

      services.niks3 = {
        s3 = {
          endpoint = "ACCOUNT_ID.r2.cloudflarestorage.com";
          bucket = "BUCKET";
        };
        cacheUrl = "https://CACHE_DOMAIN";
        serverUrl = "https://NIKS3_DOMAIN";
        database.connectionString = "postgres://SERVICE_ACCOUNT%40PROJECT.iam@127.0.0.1:5432/niks3?sslmode=disable";
        oidc.providers.github = {
          issuer = "https://token.actions.githubusercontent.com";
          audience = "https://NIKS3_DOMAIN";
          boundClaims.repository_owner = [ "GITHUB_OWNER" ];
        };
      };

      systemd.services.niks3 = {
        after = [ "cloud-sql-proxy.service" ];
        requires = [ "cloud-sql-proxy.service" ];
      };
    };
}
