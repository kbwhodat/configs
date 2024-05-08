{ pkgs, ... }:

{
# Add dash to the Home Manager environment
	home.packages = with pkgs; [
		dash
		tcsh
		ksh
	];

}
