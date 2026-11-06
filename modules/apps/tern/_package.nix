{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeDesktopItem,
  makeWrapper,
  versionCheckHook,
  git,
  python3,
  libglvnd,
  vulkan-loader,
  wayland,
  libxkbcommon,
  libxcb,
  libpulseaudio,
  linux-pam,
  webkitgtk_4_1,
}:
let
  desktopItem = makeDesktopItem {
    name = "so.stencil.tern";
    desktopName = "Tern";
    exec = "tern %F";
    icon = "so.stencil.tern";
    startupWMClass = "so.stencil.tern";
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
    python3
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
    webkitgtk_4_1
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 tern $out/libexec/tern/tern
    makeWrapper $out/libexec/tern/tern $out/bin/tern \
      --prefix PATH : ${lib.makeBinPath [ git ]}

    install -Dm644 -t $out/share/applications ${desktopItem}/share/applications/so.stencil.tern.desktop

    python3 - tern $out/share/icons/hicolor <<'EOF'
    import os, struct, sys

    data = open(sys.argv[1], "rb").read()
    sizes = {32, 48, 64, 128, 256, 512, 1024}
    found = {}
    i = 0
    while (i := data.find(b"\x89PNG\r\n\x1a\n", i)) != -1:
        start, pos = i, i + 8
        i += 8
        if data[pos + 4 : pos + 8] != b"IHDR":
            continue
        width, height = struct.unpack(">II", data[pos + 8 : pos + 16])
        if width != height or width not in sizes or width in found:
            continue
        while pos + 8 <= len(data):
            length, kind = struct.unpack(">I4s", data[pos : pos + 8])
            pos += 12 + length
            if kind == b"IEND":
                found[width] = data[start:pos]
                break
    if not found:
        sys.exit("no embedded icons found")
    for size, png in found.items():
        path = f"{sys.argv[2]}/{size}x{size}/apps/so.stencil.tern.png"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, "wb").write(png)
    EOF

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
