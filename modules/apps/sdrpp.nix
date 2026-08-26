_: {
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ sdrpp ];
    };
}
