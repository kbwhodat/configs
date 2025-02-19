{ pkgs, config, ...}:

{
  
  home.packages = with pkgs; [    
    tectonic
    texliveSmall
    pkg-config
    imagemagick
    imagemagick.dev
  ];
}
