{ inputs, ... }:
{
  flake-file.inputs.opendesign = {
    url = "git+https://forge.asnk.io/sugar/opendesign";
    inputs.home-manager.follows = "home-manager";
  };

  home = {
    imports = [ inputs.opendesign.homeModules.default ];
    programs.open-design = {
      enable = true;
      allowedInternalHosts = [ "pica" ];
    };
  };
}
