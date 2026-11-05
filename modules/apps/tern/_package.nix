{
  lib,
  stdenvNoCC,
  requireFile,
  makeDesktopItem,
  makeWrapper,
  patchelf,
  versionCheckHook,
  git,
  pkgsMusl,
  tern-runtime,
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
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tern";
  version = "0.9.12";

  src = requireFile {
    name = "Tern-${finalAttrs.version}-linux-musl-x86_64.tar.gz";
    url = "https://build.stencil.so/tern";
    hash = "sha256-+3Re4Tb10C2MEmPJlTfIEqacb+CAz3wGOYfvkv1SRwk=";
  };

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 tern $out/libexec/tern/tern
    patchelf \
      --set-interpreter ${pkgsMusl.musl}/lib/ld-musl-x86_64.so.1 \
      --set-rpath ${tern-runtime}/lib \
      $out/libexec/tern/tern

    makeWrapper $out/libexec/tern/tern $out/bin/tern \
      --unset LD_LIBRARY_PATH \
      --set __EGL_VENDOR_LIBRARY_FILENAMES ${tern-runtime}/share/glvnd/egl_vendor.d/50_mesa.json \
      --set VK_DRIVER_FILES ${
        lib.concatMapStringsSep ":" (icd: "${tern-runtime}/share/vulkan/icd.d/${icd}_icd.x86_64.json") [
          "intel"
          "radeon"
          "lvp"
        ]
      } \
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
