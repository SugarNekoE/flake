{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    llm-agents
  ];

  home =
    { pkgs, ... }:
    {
      home = {
        packages = with pkgs; [
          llm-agents.omp
          llm-agents.herdr
          llm-agents.codex
          llm-agents.grok-bot
          llm-agents.opencode2
          llm-agents.claude-code
        ];
      };
    };
}
