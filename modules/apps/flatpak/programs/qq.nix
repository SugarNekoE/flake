{ inputs, ... }:
{
  flake.modules.aspects.qq.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "com.qq.QQ" ];
}
