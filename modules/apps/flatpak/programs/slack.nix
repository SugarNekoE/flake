{ inputs, ... }:
{
  flake.modules.aspects.slack.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "com.slack.Slack" ];
}
