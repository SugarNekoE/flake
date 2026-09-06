{
  pkgs,
  lib,
  acs,
  name,
  tag ? "runner-${pkgs.forgejo-runner.version}",
  extraPackages ? [ ],
  nixSupport ? false,
  buildahSupport ? false,
}:
let
  tools =
    with pkgs;
    [
      acs
      forgejo-runner
      bashInteractive
      coreutils
      gitMinimal
      openssh
      cacert
      curl
      jq
      gnutar
      gzip
      xz
      unzip
      findutils
      gnugrep
      gnused
      gawk
      nodejs_24
      python3
    ]
    ++ extraPackages
    ++ lib.optionals buildahSupport (
      with pkgs;
      [
        buildah
        skopeo
        crun
      ]
    )
    ++ lib.optionals nixSupport (
      with pkgs;
      [
        nix
        devenv
        direnv
        cachix
        attic-client
      ]
    );
  root = pkgs.buildEnv {
    name = "acs-runner-root";
    paths = tools ++ [
      pkgs.dockerTools.usrBinEnv
      pkgs.dockerTools.binSh
    ];
    pathsToLink = [
      "/bin"
      "/etc"
      "/share"
      "/lib"
      "/include"
      "/usr"
    ];
  };
in
pkgs.dockerTools.buildLayeredImage {
  inherit name tag;
  contents = [ root ];
  includeNixDB = nixSupport;
  extraCommands = ''
    mkdir -p tmp data/home data/workspace etc
    chmod 1777 tmp
    cat > etc/passwd <<'EOF'
    root:x:0:0:root:/data/home:/bin/bash
    runner:x:1000:1000:runner:/data/home:/bin/bash
    nobody:x:65534:65534:nobody:/tmp:/bin/sh
    EOF
    cat > etc/group <<'EOF'
    root:x:0:
    runner:x:1000:
    nobody:x:65534:
    EOF
    echo 'hosts: files dns' > etc/nsswitch.conf
    ${lib.optionalString buildahSupport ''
      # Skopeo contributes this directory as a store symlink. Replace only
      # the image-local link, never write through it into the Nix store.
      if [ -L etc/containers ]; then
        rm etc/containers
      fi
      mkdir -p etc/containers var/lib/containers run/containers
      rm -f etc/containers/{storage.conf,containers.conf,registries.conf,policy.json}
      cat > etc/containers/storage.conf <<'EOF'
      [storage]
      driver = "vfs"
      runroot = "/run/containers/storage"
      graphroot = "/var/lib/containers/storage"
      EOF
      cat > etc/containers/containers.conf <<'EOF'
      [containers]
      cgroups = "disabled"
      [engine]
      runtime = "crun"
      events_logger = "file"
      EOF
      cat > etc/containers/registries.conf <<'EOF'
      unqualified-search-registries = []
      short-name-mode = "enforcing"
      EOF
      echo '{"default":[{"type":"insecureAcceptAnything"}]}' > etc/containers/policy.json
    ''}
    ${lib.optionalString nixSupport ''
      mkdir -p etc/nix
      cat > etc/nix/nix.conf <<'EOF'
      experimental-features = nix-command flakes
      sandbox = false
      build-users-group =
      accept-flake-config = false
      EOF
    ''}
  '';
  fakeRootCommands = ''
    chown -R 1000:1000 data
  '';
  enableFakechroot = true;
  config = {
    User = if nixSupport || buildahSupport then "0:0" else "1000:1000";
    WorkingDir = "/data";
    Env = [
      "PATH=/bin"
      "HOME=/data/home"
      "USER=${if nixSupport || buildahSupport then "root" else "runner"}"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NIX_REMOTE=local"
      "PKG_CONFIG_PATH=/lib/pkgconfig:/share/pkgconfig"
    ]
    ++ lib.optionals buildahSupport [
      "BUILDAH_ISOLATION=chroot"
      "STORAGE_DRIVER=vfs"
    ];
    Cmd = [
      "forgejo-runner"
      "one-job"
    ];
  };
}
