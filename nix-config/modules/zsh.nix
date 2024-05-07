{ pkgs, ... }:

{
	programs.zsh = {
		enable = true;
		shellAliases = {
			ll = "ls -l";
		};

		interactiveShellInit = ''
			export EDITOR="nvim"
			export SHELL="$(which zsh)"
			export BROWSER="firefox"
			export GOPATH="$(echo $HOME/go)"
			export PATH="/usr/local/bin:/home/katob/go/bin:/home/katob/.cargo/bin:/home/katob/.local/share/nvim/mason/bin:/usr/local/lib:/usr/local/opt/binutils/bin:/usr/local/opt/inetutils/libexec/gnubin:/usr/local/opt/openssl@3/bin:/usr/local/opt/bzip2/bin:$PATH"
			export DYLD_LIBRARY_PATH="/usr/local/lib/"
			export PATH="/opt/cuda/bin:$PATH"
			export LD_LIBRARY_PATH="/opt/cuda/lib64:$LD_LIBRARY_PATH"
# More environment variables can be added here
			'';

		enableCompletion = true;
		autosuggestion.enable = true;
		syntaxHighlighting.enable = true;
	};
}

