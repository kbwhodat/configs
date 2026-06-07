{pkgs, ...}:
{
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    # Config lives at ~/.config/aerospace/aerospace.toml, edited directly
    # (same pattern Hammerspoon uses).  We deliberately do NOT set
    # `settings = ...` here, because the home-manager module would then
    # write ~/.aerospace.toml — AeroSpace would discover both files and
    # error "ambiguous config".  By leaving `settings` unset, only the
    # ~/.config/aerospace/aerospace.toml file exists and is authoritative.
  };
}
