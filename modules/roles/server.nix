{ inputs, ... }:
{
  imports = with inputs.self.aspects; [ git.nixos ];
}
