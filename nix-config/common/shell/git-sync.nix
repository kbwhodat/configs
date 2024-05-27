{ config, pkgs, ... }:

{
  services.git-sync = {
    enable = true;
    repositories = {
      password-store = {
        path = config.home.homeDirectory + "/.password-store";
        uri = "git@github.com:kbwhodat/store-secrets.git";
      };
      vault = {
        path = config.home.homeDirectory + "/vault";
        uri = "git@github.com:kbwhodat/vault.git";
      };
    };
  };
}
