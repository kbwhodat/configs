{ inputs, config, utils, lib, pkgs, ...}:

{
	imports = [
    ./shell
    ./packages
    ./browsers
    ./editors
    ./lsp
    ./neovim
  ];
}
