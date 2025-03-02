{ pkgs, config, ...}:

{
  
  home.packages = with pkgs; [    
    pkg-config
    imagemagick
    imagemagick.dev
  ];
}
