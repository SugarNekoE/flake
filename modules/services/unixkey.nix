_: {
  nixos = {
    console.useXkbConfig = true;
    services.xserver.xkb = {
      layout = "us";
      options = "ctrl:nocaps";
    };
  };
}
