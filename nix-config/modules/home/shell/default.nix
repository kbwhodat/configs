{ inputs, pkgs, config, lib, ... }:
let cfg = config.modules.shell; in {
  options.modules.shell.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Shell + terminal bundle (zsh, bash, tmux, wezterm, alacritty, emacs, etc.)";
  };

  imports = [
    ./emacs.nix
    ./jujutsu.nix
    ./repos.nix
    ./bash.nix
    ./zsh.nix
    ./blesh.nix
    ./direnv.nix
    ./kitty.nix
    ./rio.nix
    ./tmux.nix
    ./password-store.nix
    ./gpg.nix
    ./wezterm.nix
    ./alacritty.nix
    ./sc-im.nix
    ./syncthing.nix
    ./flutter.nix
    ./bookokrat.nix
    ./wox.nix
    ./node.nix
    # ./openclaw.nix
    # ./ghostty.nix
    # ./python.nix
    # ./ghostty-hm.nix
  ];

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      BROWSER = "zen";
      TERMINAL = "wezterm";
    };

    home.shellAliases = {};
  };
}
