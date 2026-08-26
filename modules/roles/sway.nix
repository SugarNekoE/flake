{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    ly
  ];
}
