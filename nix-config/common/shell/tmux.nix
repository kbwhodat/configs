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
		terminal = "screen-256color";
		historyLimit = 100000;
		plugins = with pkgs;
		[
			tmuxPlugins.better-mouse-mode
      tmuxPlugins.fzf-tmux-url
      tmux-fzf-session-switch
      tmuxPlugins.sessionist
      tmuxPlugins.extrakto
      tmuxPlugins.resurrect
			tmuxPlugins.yank
		];

		extraConfig = ''

				set -g set-clipboard on
				setw -g mode-keys vi
				set -sg escape-time 0

        set -g @resurrect-strategy-nvim 'session'
        set -g @resurrect-strategy-vim 'session'

				# set -g default-command "/run/current-system/sw/bin/bash"
				# set-option -g default-shell "/run/current-system/sw/bin/bash"
				set -g default-command "/etc/profiles/per-user/katob/bin/zsh"
				set-option -g default-shell "/etc/profiles/per-user/katob/bin/zsh"

				set-option -g mouse on
				set -g @yank_selection_mouse 'clipboard'
				set -g cursor-color white
				set -g prefix ${ if isDarwin then "C-a" else "C-a" }
				unbind C-b
				bind C-a send-prefix
				bind R source-file ~/.config/tmux/tmux.conf \; display "Config Reloaded!"

        set -g status on
        set -g status-left '#(
          CURRENT_SESSION=$(tmux display-message -p "#S");
          tmux ls \
            | cut -d " " -f1 \
            | tr "\n" " " \
            | tr ":" " " \
            | sed "s/\b$CURRENT_SESSION\b/#[fg=yellow]&#[default]/"
        )'
        set -g status-right ""

				set-option -g status-style bg=default
        #set -g status-left "#S "
        set-option -g status-left-length 100
        set -g status-right-length 0
        #set -g status-right ""
				set -g window-status-current-format ""
				set -g window-status-format ""

        set-option -g detach-on-destroy off

        # Enable cursor blink
        set-option -g terminal-overrides ',*:cnorm=\E[?12l\E[?25h'
        set-option -ga terminal-overrides ',*:civis=\E[?25l'
        set-option -ga terminal-overrides ',*:Tc'

				set -gq allow-passthrough on
				set -g visual-activity off

				bind-key -n C-h select-pane -L
				bind-key -n C-j select-pane -D
				bind-key -n C-k select-pane -U
        bind-key -n C-l select-pane -R


				bind-key -T copy-mode-vi 'C-h' select-pane -L
				bind-key -T copy-mode-vi 'C-j' select-pane -D
				bind-key -T copy-mode-vi 'C-k' select-pane -U
				bind-key -T copy-mode-vi 'C-l' select-pane -R
				bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "xclip -selection clipboard -i"

		'';
	};

}
