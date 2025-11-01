{ inputs, config, utils, lib, pkgs, ...}:

{
	imports = [
    ./shell
    ./vms
    ./packages
    ./browsers
    ./keyboard
    ./editors
    ./lsp
    ./neovim
    ./email
  ];
}
