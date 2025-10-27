{ config, pkgs, lib, ... }:

let
  # pick ONE: classic (~/.emacs.d) or XDG (~/.config/emacs)
  useXDG = false;

  emacsDir = if useXDG then "${config.home.homeDirectory}/.config/emacs"
                        else "${config.home.homeDirectory}/.emacs.d";

in {

  programs.emacs = {
    enable = true;
    package = pkgs.emacs; 
    extraPackages = epkgs: [
      epkgs.evil
      epkgs.evil-collection
      epkgs.which-key
      epkgs.general
      epkgs.persistent-scratch

      epkgs.evil-surround         
      epkgs.evil-markdown         
      epkgs.markup         
      epkgs.evil-nerd-commenter  
      epkgs.evil-exchange       
      epkgs.evil-matchit       
      epkgs.evil-args         
      epkgs.evil-easymotion  
      epkgs.avy             
      epkgs.evil-anzu      
      epkgs.undo-fu epkgs.undo-fu-session
      epkgs.deft
      epkgs.persp-mode
      epkgs.minions

      epkgs.vertico
      epkgs.orderless
      epkgs.marginalia
      epkgs.ewal-doom-themes
      epkgs.consult
      epkgs.ripgrep               
      epkgs.project              
    ];
  };

  home.file."${emacsDir}/early-init.el".source = ./doom/early-init.el;
  home.file."${emacsDir}/init.el".source = ./doom/init.el;

  home.file."${emacsDir}/themes/doom-alabaster-theme".source = 
    pkgs.fetchFromGitHub {
      owner = "kbwhodat";
      repo = "doom-alabaster-theme";
      rev = "master";           # or a pinned commit hash if you prefer
      sha256 = "sha256-FrREa0leAqOqC50hAH1uY8VMy+CMmsSjwPN9KJ5cuPo=";
    };
}
