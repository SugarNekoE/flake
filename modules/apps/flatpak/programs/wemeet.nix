{ inputs, ... }:
{
  flake.modules.aspects.wemeet.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "com.tencent.wemeet" ];
}
