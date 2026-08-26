{ lib, ... }:
{
  options.identity = {
    sshKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Globally named SSH public keys.";
    };

    gpgKeys = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            fingerprint = lib.mkOption {
              type = lib.types.str;
              description = "GPG fingerprint or long key ID used for signing.";
            };

            privateKey = lib.mkOption {
              type = lib.types.str;
              description = "Key path of the armored private key in the SOPS document.";
            };
          };
        }
      );
      default = { };
      description = "Globally named GPG key pairs.";
    };
  };
}
