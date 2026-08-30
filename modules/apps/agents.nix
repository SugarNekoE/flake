{ inputs, lib, ... }:
let
  piSettings = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-sol";
    theme = "Monokai Pro (CE)";
  };

  piNpmPackages = {
    "npm:pi-diff-review@0.1.26" = "sha256-Auq5iZpQwEzF2/LR5WnDvrsWmh+noD6Rbn+d+fG47UQ=";
    "npm:pi-goal-x@0.30.5" = "sha256-XdI4xhUDmhL3t1oS1Nh4Db9j9h8xQPM6neTKb+ryVXI=";
    "npm:pi-mcp-adapter@2.29.0" = "sha256-OrdOu1g0OeyrcdjOSNTcj1Alv2xNTOAECZPwQBZOgL8=";
    "npm:pi-simplify@0.2.3" = "sha256-eP18i9BdSXt5p1ssc4k6bhogR3cyg0ZoFExUc/KogzE=";
    "npm:pi-web-access@0.25.0" = "sha256-DYznZFiZ93TN3puBv4ZhavRQkxfGBBkiBWeqrveDOFU=";
    "npm:pi-subagents@0.58.0" = "sha256-RWSRVZ8piZhwBJFstt2d7CLCdMBvMrY8d7a/UhcJLyw=";
    "npm:pi-btw@0.4.1" = "sha256-PJKMskXImX2dsyDdjP56DPRRvrPIUpBFl04APGdEE5c=";
    "npm:pi-better-openai@0.1.22" = "sha256-cCrd34XWA5PxmwIuyH7043ruDTYv3BdDGjHpzuQSs2Q=";
    "npm:pi-studio@0.9.52" = "sha256-W7JBgzpLsFKmP7yZ78DvFvYTE4N8RRZniIdw0vG1bQU=";
    "npm:pi-auto-reviewer@1.1.0" = "sha256-538TiFxvcqfvNLNJWNm+NurAnqKjdlUpTbNJGwOBjUY=";
    "npm:pi-sandbox@0.6.5" = "sha256-Ysc58WDgKlX6dGnhJw0gQU7vT8sZ3ecuF5ng60tTxwo=";
    "npm:@ff-labs/pi-fff@0.10.5" = "sha256-KfilZVZohnisnbQ8XO7+50TQzSaIrw6DpLxA5XRIi+w=";
    "npm:@narumitw/pi-usage@0.54.0" = "sha256-7wFMNCnVi6ynJyjcNxoqfTAK+j5xD/PPhSdCD5Fns8Q=";
    "npm:@krfantasy/pi-monokai-pro@0.1.0" = "sha256-7ti+iHnkpKmqQ0rbJHcyU9YC82Cni3kvKmYL0kfCEf4=";
  };

  parseNpmSpec =
    source:
    let
      npmSpec = lib.removePrefix "npm:" source;
      slashParts = lib.splitString "/" npmSpec;
      scoped = lib.hasPrefix "@" npmSpec;
      scope = builtins.elemAt slashParts 0;
      unscopedSpec = if scoped then builtins.concatStringsSep "/" (builtins.tail slashParts) else npmSpec;
      versionParts = lib.splitString "@" unscopedSpec;
      name = builtins.elemAt versionParts 0;
    in
    {
      name = if scoped then "${scope}/${name}" else name;
      version = if builtins.length versionParts > 1 then builtins.elemAt versionParts 1 else "latest";
    };

  mkPiNpmPackage =
    pkgs: source: hash:
    let
      package = parseNpmSpec source;
      pname = "pi-npm-package-${lib.strings.sanitizeDerivationName package.name}";
      packageJson = builtins.toJSON {
        name = pname;
        version = "0.0.0";
        private = true;
        dependencies.${package.name} = package.version;
      };
      packageSrc = pkgs.runCommand "${pname}-src" { } ''
        mkdir -p $out
        printf %s ${lib.escapeShellArg packageJson} > $out/package.json
      '';
      npmFlags = [ "--legacy-peer-deps" ];
      nodeModulesLinkTarget = if lib.hasPrefix "@" package.name then "../.." else "..";
    in
    pkgs.buildNpmPackage {
      inherit pname npmFlags;
      inherit (package) version;
      nativeBuildInputs = lib.optional (package.name == "pi-better-openai") pkgs.autoPatchelfHook;
      buildInputs = lib.optional (package.name == "pi-better-openai") pkgs.stdenv.cc.cc.lib;
      src = packageSrc;
      npmDeps = pkgs.fetchNpmDeps {
        name = "${pname}-${package.version}-npm-deps";
        src = packageSrc;
        nativeBuildInputs = [ pkgs.nodejs ];
        NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        postPatch = ''
          export HOME=$TMPDIR/home
          export npm_config_cache=$TMPDIR/npm-cache
          mkdir -p "$HOME"
          npm install --package-lock-only --ignore-scripts ${lib.escapeShellArgs npmFlags}
        '';
        inherit hash;
      };
      dontNpmBuild = true;
      postPatch = ''
        cp "$npmDeps/package-lock.json" package-lock.json
      '';
      installPhase = ''
        runHook preInstall
        test -d ${lib.escapeShellArg "node_modules/${package.name}"}
        mkdir -p "$out"
        cp -R node_modules "$out/node_modules"
        if [ ! -e "$out/node_modules/${package.name}/node_modules" ]; then
          ln -s ${lib.escapeShellArg nodeModulesLinkTarget} "$out/node_modules/${package.name}/node_modules"
        fi
        ln -s ${lib.escapeShellArg "node_modules/${package.name}"} "$out/package"
        runHook postInstall
      '';
    };
in
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  nixos = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };

  home =
    { pkgs, ... }:
    let
      jsonFormat = pkgs.formats.json { };
      packagePaths = lib.mapAttrsToList (
        source: hash: "${mkPiNpmPackage pkgs source hash}/package"
      ) piNpmPackages;
      settingsFile = jsonFormat.generate "pi-settings.json" (piSettings // { packages = packagePaths; });
    in
    {
      home = {
        packages = [
          pkgs.bubblewrap
          pkgs.ripgrep
          pkgs.socat
        ]
        ++ (with pkgs.llm-agents; [
          pi
        ]);
        file.".pi/agent/settings.json".source = settingsFile;
      };
    };
}
