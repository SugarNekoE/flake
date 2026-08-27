_: {
  home = { pkgs, ... }: {
    home.packages = with pkgs; [
      ffmpeg
      unstable.davinci-resolve-studio
    ];
  };
}
