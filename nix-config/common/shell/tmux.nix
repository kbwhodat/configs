{ pkgs, config, ...}: 

{

	programs.tmux = {
		enable = true;
		#terminal = "screen-256color";
		historyLimit = 100000;
		plugins = with pkgs;
		[
			tmuxPlugins.better-mouse-mode
			# tmuxPlugins.urlview
			tmuxPlugins.yank
		];

		extraConfig = ''

				set -g set-clipboard on
				setw -g mode-keys vi
				set -sg escape-time 0

				set -g default-command "/run/current-system/sw/bin/bash"
				set-option -g default-shell "/run/current-system/sw/bin/bash"

				set-option -g mouse on
				set -g @yank_selection_mouse 'clipboard'
				set -g cursor-color white
				set -g prefix C-a
				unbind C-b
				bind C-a send-prefix
				bind R source-file ~/.tmux.conf \; display "Config Reloaded!"

				set-option -g status-style bg=default
				set -g status-left "#S "
				set -g status-right ""
				set -g window-status-current-format ""
				set -g window-status-format ""

				# set -sa terminal-overrides ',xterm-kitty:RGB,*:Ss=\033[0 q'
        set-option -a terminal-features 'XXX:RGB'

				set -gq allow-passthrough on
				set -g visual-activity off

				bind-key -n C-h select-pane -L
				bind-key -n C-j select-pane -D
				bind-key -n C-k select-pane -U

				bind-key -T copy-mode-vi 'C-h' select-pane -L
				bind-key -T copy-mode-vi 'C-j' select-pane -D
				bind-key -T copy-mode-vi 'C-k' select-pane -U
				bind-key -T copy-mode-vi v send-keys -X begin-selection

		'';
	};

}
