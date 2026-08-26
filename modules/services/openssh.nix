{ inputs, ... }:
let
  withKnownHosts = knownHosts: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.openssh ];
    nixosModule.programs.ssh.knownHosts = knownHosts;
  };
in
{
  aspectHelpers.openssh = { inherit withKnownHosts; };

  nixos =
    { ... }:
    {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };
    };
}
