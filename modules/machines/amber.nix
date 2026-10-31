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
    (cloud-sql-proxy.withInstance "project-48516ea4-5e61-4dea-8a1:us-central1:amber-db")
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
          endpoint = "297bf25f648e310a3564843054342e44.r2.cloudflarestorage.com";
          bucket = "amber";
        };
        cacheUrl = "https://cache.asnk.io";
        serverUrl = "https://amber.asnk.io";
        database.connectionString = "postgres://amber-vm%40project-48516ea4-5e61-4dea-8a1.iam.gserviceaccount.com@127.0.0.1:5432/amber?sslmode=disable";
        oidc.providers.forgejo = {
          issuer = "https://forge.asnk.io/api/actions";
          audience = "https://amber.asnk.io";
          boundClaims.repository_owner = [ "sugar" ];
        };
      };

      systemd.services.niks3 = {
        after = [ "cloud-sql-proxy.service" ];
        requires = [ "cloud-sql-proxy.service" ];
      };
    };
}
