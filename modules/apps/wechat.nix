_: {
  home =
    { lib, pkgs, ... }:
    {
      home.packages = [
        (pkgs.unstable.wechat.override {
          fetchurl =
            args:
            pkgs.unstable.fetchurl (
              args
              // lib.optionalAttrs (args ? netrcPhase) {
                netrcPhase = args.netrcPhase + ''
                  if [[ ''${urls[0]} != "$url" && -z $(curl -fsSIL -o /dev/null -w '%header{x-cos-version-id}' "$url") ]]; then
                    urls=("$url" "''${urls[@]}")
                  fi
                '';
              }
            );
        })
      ];
    };
}
