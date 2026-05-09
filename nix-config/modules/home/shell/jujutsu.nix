{ config, pkgs, ...}:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "byantalok@yahoo.com";
        name = "kbwhodat";
      };
    };
  };
}
