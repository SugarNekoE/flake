{
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kind
        kubectl
        k0sctl
        k9s
        skopeo
      ];
    };
}
