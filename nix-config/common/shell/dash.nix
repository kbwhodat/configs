{ pkgs, ... }:

{
# Optional: Configure dash as the default shell
# Adjust this according to your needs
	programs.dash = {
		enable = true;  # This might not be necessary unless there's a specific module for dash
	};
}
