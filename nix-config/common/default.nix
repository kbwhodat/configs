{ inputs, config, utils, lib, pkgs, ...}:

{
	imports = [
    ./shell
    ./packages
    ./browsers
    ./keyboard
    ./editors
    ./lsp
    ./neovim
    ./email
  ];
}
