{ inputs, ... }:
{
  flake.modules.aspects.mission-center.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "io.missioncenter.MissionCenter" ];
}
