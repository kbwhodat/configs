{ pkgs, config, ... }:

{
  imports = [ ../../modules/zen.nix ];

  programs.zen-browser = {
    enable = true;
    package = pkgs.zen-browser-bin.override {
      nativeMessagingHosts = [
        # Gnome shell native connector
        pkgs.gnome-browser-connector
        # Tridactyl native connector
        pkgs.tridactyl-native
      ];
    };
  };
}
