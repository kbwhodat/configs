{ config, lib, pkgs, ... }:

{
  home.activation.installNeovim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f ${config.home.homeDirectory}/.neovim_installed ]; then
      ${pkgs.nodePackages.yarn}/bin/yarn global add neovim
    fi
  '';
}
