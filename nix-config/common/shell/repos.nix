{ config, pkgs, ... }:

{
  home.activation.cloneVault = ''
		if [ ! -d ${config.home.homeDirectory}/vault ]; then
			${pkgs.git}/bin/git clone https://github.com/kbwhodat/vault ${config.home.homeDirectory}/vault
		fi
  '';

  # home.activation.clonePasswordStore = ''
  # if [ ! -d ${config.home.homeDirectory}/.password-store ]; then
  # 	${pkgs.git}/bin/git clone https://github.com/kbwhodat/store-secrets ${config.home.homeDirectory}/.password-store
  # fi
  # '';
}
