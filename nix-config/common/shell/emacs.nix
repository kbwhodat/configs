{ config, pkgs, lib, ... }:

let
  # pick ONE: classic (~/.emacs.d) or XDG (~/.config/emacs)
  useXDG = false;

  emacsDir = if useXDG then "${config.home.homeDirectory}/.config/emacs"
                        else "${config.home.homeDirectory}/.emacs.d";

  doomDir  = if useXDG then "${config.home.homeDirectory}/.config/doom"
                        else "${config.home.homeDirectory}/.doom.d";
in {

  programs.emacs = {
    enable = true;
    package = pkgs.emacs; # or pkgs.emacs29-pgtk, pkgs.emacs-30, etc.
  };

  home.file."${doomDir}/config.el".source = ./doom/config.el;
  home.file."${doomDir}/init.el".source = ./doom/init.el;
  home.file."${doomDir}/packages.el".source = ./doom/packages.el;

  # Bootstrap + sync Doom at activation time
  home.activation.installDoomEmacs =
    lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" "linkGeneration" "onFilesChange" "setupLaunchAgents" "sops-nix" ] ''
      export HOME="${config.home.homeDirectory}"
      export PATH="${pkgs.git}/bin:${pkgs.ripgrep}/bin:${pkgs.fd}/bin:${pkgs.gcc}/bin:${pkgs.unzip}/bin:/run/current-system/sw/bin:${pkgs.emacs}/bin:$PATH"

      ${lib.optionalString useXDG ''export DOOMDIR="${doomDir}"''}

      if [ ! -d "${emacsDir}" ]; then
        git clone https://github.com/hlissner/doom-emacs "${emacsDir}"
      fi

      "${emacsDir}"/bin/doom sync

    '';
}
