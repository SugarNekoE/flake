_: {
  home =
    { pkgs, lib, ... }:
    let
      davinciResolveStudio = pkgs.unstable.davinci-resolve-studio.override {
        runCommandLocal =
          name: attrs:
          pkgs.unstable.runCommandLocal name (
            attrs
            //
              lib.optionalAttrs
                (attrs.outputHash or null == "sha256-D5RjUukwKMpULrDfMJOPsPWW9FxhQ/IUMh76u5JLytA=")
                {
                  outputHash = "sha256-P+zu8/OuFcDcIkwV3UMq0qg9U2JEGRkKDP+VLQesZjw=";
                }
          );
      };
    in
    {
      home.packages = [
        pkgs.ffmpeg
        davinciResolveStudio
      ];
    };
}
