{ inputs, ... }:
{
  flake.modules.aspects.wechat.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "com.tencent.WeChat" ];
}
