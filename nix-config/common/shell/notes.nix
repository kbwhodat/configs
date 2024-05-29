{ config, pkgs, ... }:

{

  home.file."vault".target = "${config.home.homeDirectory}/vault";
  
  home.activation.cloneRepos = ''
    git clone https://github.com/kbwhodat/vault ${config.home.homeDirectory}/vault
  '';
}
