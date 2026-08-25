{ lib, ... }:
{
  options.identity = {
    sshKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Globally named SSH public keys.";
    };

    gpgKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Globally named GPG public-key fingerprints.";
    };
  };
}
