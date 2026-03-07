{ config, pkgs, inputs, ...}:
let
  unstable = import inputs.unstable {
    system = pkgs.system;
    config = pkgs.config;
  };
in
{
  programs = {
    direnv = {
      enable = true;
      package = unstable.direnv;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    bash.enable = true;
    zsh.enable = true;
  };
}
