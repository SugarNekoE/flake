{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
  };

  nixos = {
    nix.settings = {
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };

  home =
    { pkgs, ... }:
    let
      agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      opencode-wrapper = pkgs.writeShellScriptBin "opencode" ''
        exec ${agents.opencode2}/bin/opencode2 "$@"
      '';
    in
    {
      home = {
        packages = [
          agents.herdr
          agents.opencode2
          agents.claude-code
          pkgs.bubblewrap
          opencode-wrapper
        ];
      };
    };
}
