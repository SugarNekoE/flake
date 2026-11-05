{ pkgsMusl }:
let
  mesa = pkgsMusl.mesa.override {
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
pkgsMusl.symlinkJoin {
  name = "tern-runtime";
  paths = with pkgsMusl; [
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
