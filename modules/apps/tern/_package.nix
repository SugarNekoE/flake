{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeDesktopItem,
  makeWrapper,
  versionCheckHook,
  git,
  libglvnd,
  vulkan-loader,
  wayland,
  libxkbcommon,
  libxcb,
  libpulseaudio,
  linux-pam,
}:
let
  desktopItem = makeDesktopItem {
    name = "tern";
    desktopName = "Tern";
    exec = "tern %F";
    mimeTypes = [ "x-scheme-handler/tern" ];
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "tern";
  version = "0.9.12";

  src = requireFile {
    name = "Tern-${finalAttrs.version}-linux-x86_64.tar.gz";
    url = "https://build.stencil.so/tern";
    hash = "sha256-9n6MK/9DfzNlrjpHi7wY9jr7blO9bnzVVrrHziTRNpM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [ (lib.getLib stdenv.cc.cc) ];

  runtimeDependencies = [
    libglvnd
    vulkan-loader
    wayland
    libxkbcommon
    libxcb
    libpulseaudio
    linux-pam
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 tern $out/libexec/tern/tern
    makeWrapper $out/libexec/tern/tern $out/bin/tern \
      --prefix PATH : ${lib.makeBinPath [ git ]}

    install -Dm644 -t $out/share/applications ${desktopItem}/share/applications/tern.desktop

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Stencil's native terminal workspace";
    homepage = "https://stencil.so/tern";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "tern";
  };
})
