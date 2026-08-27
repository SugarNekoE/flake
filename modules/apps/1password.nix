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

      xdg.configFile."1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        vault = "Personal"

        [[ssh-keys]]
        vault = "Servers"
      '';

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [ onePasswordConfig ];
        settings."*".IdentityAgent = sshAgentSocket;
      };
    };
}
