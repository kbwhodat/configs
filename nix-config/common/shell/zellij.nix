{ config, pkgs, ...}:

{
  programs.zellij = {
    enable = false;
    enableBashIntegration = true;
    # settings =
    # {
    #       default_layout = "compact";
    #       ui.pane_frames.rounded_corners = false;
    #       ui.pane_frames.hide_session_name = false;
    # };
  };
}
