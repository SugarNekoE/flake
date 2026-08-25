{ inputs, ... }:
{
  flake.modules.aspects.server.imports = with inputs.self.aspects; [ git.nixos ];
}
