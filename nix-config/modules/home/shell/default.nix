{ inputs, pkgs, config, lib, ... }:
let cfg = config.modules.shell; in {
  options.modules.shell.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Shell + terminal bundle (zsh, bash, tmux, wezterm, alacritty, emacs, etc.)";
  };

  # Gate for PERSONAL tools living under shell/, referenced from their
  # bare-config sub-files.  Default true = personal hosts unchanged;
  # profiles/home/work.nix flips them off (work-laptop isolation).
  options.modules.shell.bookokrat.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "bookokrat reader + techdict (personal — off on work)";
  };
  options.modules.shell.claude-acp.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "claude-agent-acp bridge for emacs agent-shell (npm-fetched — off on work, Zscaler blocks npm)";
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
    ./gpg.nix
    ./wezterm.nix
    ./alacritty.nix
    ./sc-im.nix
    ./syncthing.nix
    ./flutter.nix
    ./bookokrat.nix
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
