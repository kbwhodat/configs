{ lib, pkgs, config, ...}:
let
  tmux-fzf-session-switch = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-fzf-session-switch";
    version = "";
    src = pkgs.fetchFromGitHub {
      owner = "kbwhodat";
      repo = "tmux-fzf-session-switch";
      rev = "94c69808d9457903073431f5db95a028289c9196";
      sha256 = "0wnn50k5fy4ngjd16k3abg49x1pfx7i5vzd4kkjs7k8v0k203p79";
    };
  };
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

				set -g default-command "/run/current-system/sw/bin/bash"
				set-option -g default-shell "/run/current-system/sw/bin/bash"

				set-option -g mouse on
				set -g @yank_selection_mouse 'clipboard'
				set -g cursor-color white
				set -g prefix C-a
				unbind C-b
				bind C-a send-prefix
				bind R source-file ~/.config/tmux/tmux.conf \; display "Config Reloaded!"

				set-option -g status-style bg=default
				set -g status-left "#S "
        set-option -g status-left-length 50
        set -g status-right-length 10
				set -g status-right ""
				set -g window-status-current-format ""
				set -g window-status-format ""

				# set -sa terminal-overrides ',xterm-kitty:RGB,*:Ss=\033[0 q'
        # set-option -ga terminal-overrides ',xterm-ghostty:cnorm=\E[?12h\E[?25h'

        # Enable cursor blink
        set-option -g terminal-overrides ',*:cnorm=\\E[?12l\\E[?25h'
        set-option -ga terminal-overrides ',*:civis=\\E[?25l'
        set-option -ga terminal-overrides ',xterm-ghostty:cnorm=\E[?12h\E[?25h'
        set-option -ga terminal-overrides ',xterm-kitty:cnorm=\E[?12h\E[?25h'
        set-option -ga terminal-overrides ',screen-256color:cnorm=\\E[?12h\\E[?25h'
        set -g terminal-overrides '*:colors=256'

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
