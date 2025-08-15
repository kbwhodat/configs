{ lib, pkgs, config, ...}:
let
  tmux-fzf-session-switch = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-fzf-session-switch";
    version = "";
    src = pkgs.fetchFromGitHub {
      owner = "kbwhodat";
      repo = "tmux-fzf-session-switch";
      rev = "fe665f446fbe8727eb010ae157de618a67641bd4";
      sha256 = "sha256-3ECDIw+hbDn8Zc+e9rwRUljm7SlN1w7VeLsp7SLcW8Q=";
    };
  };
  tmux-copyrat = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-copyrat";
    version = "";
    src = pkgs.fetchFromGitHub {
      owner = "kbwhodat";
      repo = "tmux-copyrat";
      rev = "b0ba5434b04f10db6ad490564fdf2a0f79a68d11";
      sha256 = "sha256-4evkHJYqfqoG5VU+kZCpJO1etaityS3hGDgCr198WFg=";
    };
  };
  inherit (pkgs.stdenv) isDarwin;
in
{
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    historyLimit = 100000;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.fzf-tmux-url
      tmux-fzf-session-switch
      tmux-copyrat
      tmuxPlugins.fingers
      tmuxPlugins.sessionist
      # tmuxPlugins.extrakto
      tmuxPlugins.resurrect
      tmuxPlugins.yank
      tmuxPlugins.continuum
      tmuxPlugins.copycat
    ];

    extraConfig = ''

      set -g set-clipboard on
      setw -g mode-keys vi
      set -sg escape-time 0

      set -g status on
      set -g status-left-length 100
      set -g status-right-length 50
      set -g status-interval 5

      set -g mouse on
      set -g @yank_selection_mouse 'clipboard'
      set -g cursor-color white

      set -g default-command "/etc/profiles/per-user/katob/bin/zsh"
      set -g default-shell   "/etc/profiles/per-user/katob/bin/zsh"

      # Resurrect settings
      set -g @resurrect-capture-pane-contents 'on'

      # Prefix
      set -g prefix ${ if isDarwin then "C-a" else "C-a" }
      unbind C-b
      bind C-a send-prefix
      bind R source-file ~/.config/tmux/tmux.conf \; display "Config Reloaded!"

      set -g status-left '#(
        CURRENT_SESSION=$(tmux display-message -p "#S");
        tmux ls \
          | cut -d " " -f1 \
          | tr "\n" " " \
          | tr ":" " " \
          | sed "s/\b$CURRENT_SESSION\b/#[fg=yellow]&#[default]/"
      )'


      set -g status-right '#(${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh)'

      set -g status-interval 15

      set -g status-style bg=default

      set -g window-status-current-format ""
      set -g window-status-format ""

      set -g detach-on-destroy off

      # Terminal overrides
      set -ga terminal-overrides ',*:cnorm=\E[?12l\E[?25h'
      set -ga terminal-overrides ',*:civis=\E[?25l'
      set -ga terminal-overrides ',*:Tc'

      set -gq allow-passthrough on
      set -g visual-activity off

      # Pane movement (normal + copy mode)
      bind-key -n C-h select-pane -L
      bind-key -n C-j select-pane -D
      bind-key -n C-k select-pane -U
      bind-key -n C-l select-pane -R

      bind-key -T copy-mode-vi C-h select-pane -L
      bind-key -T copy-mode-vi C-j select-pane -D
      bind-key -T copy-mode-vi C-k select-pane -U
      bind-key -T copy-mode-vi C-l select-pane -R
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "xclip -selection clipboard -i"

      # Continuum settings
      set -g @resurrect-strategy-nvim 'session'
      set -g @resurrect-strategy-vim  'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '10'
    '';
  };
}
