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
      tmuxPlugins.jump
      tmuxPlugins.fuzzback
      tmuxPlugins.sessionist
      # extrakto: fzf-pick any word/path/url from scrollback, insert at
      # prompt or copy — keyboard replacement for mouse-selecting output.
      # Default binding: prefix + Tab.  Was commented out historically;
      # the old nixpkgs breakages (unpatched python shebang, missing
      # clipboard tools on PATH) are both fixed in the pinned rev
      # (0-unstable-2025-07-27, verified: extrakto.py runs on darwin).
      tmuxPlugins.extrakto
      # fingers: hint-style copy (prefix + F) — overlays a letter on
      # every URL/IP/path/SHA on screen; press the letter, it's on the
      # clipboard.  Zero typing, complements extrakto (which needs a
      # few chars of fuzzy input but handles arbitrary tokens).  The
      # maintained successor to the abandoned tmux-thumbs.
      tmuxPlugins.fingers
      tmuxPlugins.resurrect
      tmuxPlugins.yank
      tmuxPlugins.continuum
    ];

    extraConfig = ''

      set -g set-clipboard on
      set -g focus-events on
      setw -g mode-keys vi
      set -sg escape-time 0

      set -g copy-mode-match-style 'fg=black,bg=yellow,bold'

      # Incremental search: matches highlight live as you type, like
      # vim's `/'.  (Was a one-shot prompt search before.)
      bind-key / copy-mode \; command-prompt -i -p "search:" \
        "send -X search-backward-incremental \"%%%\""
      bind-key -T copy-mode-vi / command-prompt -i -p "search:" \
        "send -X search-backward-incremental \"%%%\""

      unbind-key n
      unbind-key N

      bind-key -T copy-mode-vi n send -X search-again
      bind-key -T copy-mode-vi N send -X search-reverse

      set -g status on
      set -g status-left-length 100
      set -g status-right-length 50
      set -g status-interval 5

      set -g mouse on
      set -g window-size latest
      set -g aggressive-resize on
      set -g @yank_selection_mouse 'clipboard'
      set -g cursor-color white

      # Minimal pane borders: neutral inactive + dim active
      set -g pane-border-style 'fg=colour239'
      set -g pane-active-border-style 'fg=colour255,bold'
      set -g pane-border-lines simple
      set -g pane-border-status off

      # Keep pane-number overlay visible and high contrast when needed
      set -g display-panes-time 1500
      set -g display-panes-colour colour250
      set -g display-panes-active-colour colour45

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


      set -g status-style bg=default

      set -g window-status-current-format ""
      set -g window-status-format ""

      set -g detach-on-destroy off

      # inside-tmux TERM
      set -g default-terminal "xterm-256color"

      # truecolor support
      set -as terminal-features 'xterm*:RGB'
      set -as terminal-features 'xterm-kitty:RGB'

      # Forward modified Enter / Shift-Enter etc. — required by Pi (and other TUIs)
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -as terminal-features 'xterm*:extkeys'

      set -ga allow-passthrough all
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
      bind-key q display-panes
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      # Platform clipboard for mouse-drag copy: pbcopy on macOS (xclip
      # doesn't exist there), xclip on linux/X11.
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "${if isDarwin then "pbcopy" else "xclip -selection clipboard -i"}"

      # Pane resize (repeatable: prefix once, then tap H/J/K/L).
      # NB: shadows default prefix+L (last session) — fzf session
      # switch + sessionist cover that.
      bind-key -r H resize-pane -L 5
      bind-key -r J resize-pane -D 5
      bind-key -r K resize-pane -U 5
      bind-key -r L resize-pane -R 5

      # Floating scratch shell over the current session (prefix+t;
      # shadows the clock).  Opens in the pane's cwd; exit to dismiss.
      bind-key t display-popup -E -d "#{pane_current_path}" -w 80% -h 75%

      # Continuum settings
      set -g @resurrect-strategy-nvim 'session'
      set -g @resurrect-strategy-vim  'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '10'

      set -g status-right '#(sleep 5; ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh)'

      set -g status-interval 15

      set -g @fuzzback-hide-preview 1
      set -g @fuzzback-popup 0


    '';
  };
}
