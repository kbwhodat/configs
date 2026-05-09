{
	pkgs,
	config,
	...
}: {


  home.packages = with pkgs; [
    i3-resurrect
  ];

	home.file.".config/i3/config".source = ./config;

}
