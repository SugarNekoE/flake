{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    paseo
    llm-agents
  ];

  home =
    { pkgs, ... }:
    {
      home = {
        packages = with pkgs; [
          llm-agents.omp
          llm-agents.herdr
          llm-agents.grok-bot
        ];
      };
    };
}
