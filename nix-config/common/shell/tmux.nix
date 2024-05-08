{ pkgs, config, ...}: 

{

	programs.tmux = {
		enable = true;
		terminal = "tmux-256color";
		historyLimit = 100000;
		plugins = with pkgs;
		[
			tmuxPlugins.better-mouse-mode
			tmuxPlugins.urlview
			tmuxPlugins.yank
		];

		extraConfig = ''

# Enable clipboard and vi mode for copy-paste operations
				set -g set-clipboard on
				setw -g mode-keys vi
				set -sg escape-time 500

				set -g default-shell ${pkgs.zsh}

# Basic settings
				set-option -g mouse on
				set -g @yank_selection_mouse 'clipboard'
				set -g cursor-color white
				set -g prefix C-a
				unbind C-b
				bind C-a send-prefix
				bind R source-file ~/.tmux.conf \; display "Config Reloaded!"

# Status Bar - simplified
				set-option -g status-style bg=default
				set -g status-left "#S "
				set -g status-right ""
				set -g window-status-current-format ""
				set -g window-status-format ""

# Used for image.nvim. To be able to show images.
				set -gq allow-passthrough on
				set -g visual-activity off

# Pane navigation bindings using Ctrl+h/j/k
				bind-key -n C-h select-pane -L
				bind-key -n C-j select-pane -D
				bind-key -n C-k select-pane -U

# Enhanced pane navigation in copy-mode
				bind-key -T copy-mode-vi 'C-h' select-pane -L
				bind-key -T copy-mode-vi 'C-j' select-pane -D
				bind-key -T copy-mode-vi 'C-k' select-pane -U
				bind-key -T copy-mode-vi v send-keys -X begin-selection

		'';
	};

}
