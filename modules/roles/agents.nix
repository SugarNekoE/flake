{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    llm-agents
    paseo-desktop
  ];

  home =
    { pkgs, ... }:
    let
      opencode-wrapper = pkgs.writeShellScriptBin "opencode" ''
        exec ${pkgs.llm-agents.opencode2}/bin/opencode2 "$@"
      '';
    in
    {
      home = {
        packages = [
          pkgs.llm-agents.herdr
          pkgs.llm-agents.codex
          pkgs.llm-agents.grok-bot
          pkgs.llm-agents.opencode2
          pkgs.llm-agents.claude-code
          opencode-wrapper
        ];
      };
    };
}
