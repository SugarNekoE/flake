{ pkgsMusl }:
let
  muslPkgs = pkgsMusl.extend (
    _: prev: {
      tzdata = prev.tzdata.overrideAttrs { doCheck = false; };
    }
  );
  mesa = muslPkgs.mesa.override {
    galliumDrivers = [
      "iris"
      "llvmpipe"
      "radeonsi"
      "zink"
    ];
    vulkanDrivers = [
      "amd"
      "intel"
      "swrast"
    ];
    vulkanLayers = [ "device-select" ];
  };
in
muslPkgs.symlinkJoin {
  name = "tern-runtime";
  paths = with muslPkgs; [
    musl
    stdenv.cc.cc.lib
    libglvnd
    vulkan-loader
    wayland
    libxkbcommon
    libxcb
    libpulseaudio
    linux-pam
    mesa
  ];
}
