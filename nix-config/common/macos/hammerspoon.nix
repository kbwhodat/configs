{config, ...}:
{
  home.file.".hammerspoon" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/hammerspoon";
  };
}
