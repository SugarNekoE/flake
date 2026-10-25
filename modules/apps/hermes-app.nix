{
  flake-file.inputs.hermes-agent.url = "github:NousResearch/hermes-agent";

  home = { inputs, ... }: {
    imports = [ inputs.hermes-agent.homeManagerModules.default ];

    programs.hermes-agent = {
      enable = true;
      desktop.enable = true;
    };
  };
}
