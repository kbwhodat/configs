{ config, lib, pkgs, ... }:

{
  home.activationScripts.installNeovim = {
    text = ''
      if [ ! -f ${config.home.homeDirectory}/.neovim_installed ]; then
        npm install -g neovim
        touch ${config.home.homeDirectory}/.neovim_installed
      fi
    '';
    deps = [ "writeBoundary" ];
  };
}
