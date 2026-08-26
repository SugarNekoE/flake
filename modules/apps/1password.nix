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
      onePasswordConfig = "${config.home.homeDirectory}/.ssh/1Password/config";
    in
    {
      home.sessionVariables.SSH_AUTH_SOCK = sshAgentSocket;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [ onePasswordConfig ];
        settings."*".IdentityAgent = sshAgentSocket;
      };
    };
}
