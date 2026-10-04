_: {
  nixos = {
    console.useXkbConfig = true;
    services.xserver.xkb = {
      layout = "us";
      options = "ctrl:nocaps";
    };
  };

  darwin.system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
}
