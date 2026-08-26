_: {
  nixos =
    { user, ... }:
    {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ user.username ];
      };
    };

  home =
    { config, ... }:
    let
      sshAgentSocket = "${config.home.homeDirectory}/.1password/agent.sock";
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*".IdentityAgent = sshAgentSocket;
      };
    };
}
