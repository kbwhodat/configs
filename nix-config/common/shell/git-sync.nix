{ config, pkgs, ... }:

{
  home.file."password-store".target = "${config.home.homeDirectory}/.password-store";
  home.file."password-store".source = builtins.fetchGit {
    url = "git@github.com:kbwhodat/store-secrets.git";
    ref = "master";
    rev = "749dbdbfee5acea3f744fa33e1e435c66aa0b99c";
  };


  home.file."vault".target = "${config.home.homeDirectory}/.vault";
  home.file."vault".source = builtins.fetchGit {
    url = "git@github.com:kbwhodat/vault.git";
    ref = "master";
    rev = "0758e627b0a0d7d5e4177918f45e8edaa0c79e82";
  };

}
