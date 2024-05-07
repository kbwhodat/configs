{ pkgs, ... }:

{
	programs.zsh = {
		enable = false;
		shellAliases = {
			ll = "ls -l";
		};

		enableCompletion = true;
		autosuggestion.enable = true;
		syntaxHighlighting.enable = true;
	};
}

