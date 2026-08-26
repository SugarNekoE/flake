{ lib, ... }:
let
  userProfileType = lib.types.submodule {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "System and Home Manager username.";
      };

      fullName = lib.mkOption {
        type = lib.types.str;
        description = "Display name shared by user-facing modules.";
      };

      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address shared by user-facing modules.";
      };

      git.signingKey = lib.mkOption {
        type = lib.types.str;
        description = "Named identity.gpgKeys entry used for Git commit signing.";
      };
    };
  };
in
{
  options.userProfiles = lib.mkOption {
    type = lib.types.lazyAttrsOf userProfileType;
    default = { };
    description = "Reusable user profiles available to Aspect machines.";
  };
}
