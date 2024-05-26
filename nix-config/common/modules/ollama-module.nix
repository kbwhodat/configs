{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types;

  cfg = config.services.ollama;
  ollamaPackage = cfg.package.override {
  inherit (cfg) acceleration;
  };
  inherit (pkgs.stdenv) isDarwin;
in {
  options = {
    services.ollama = {
      enable = lib.mkEnableOption (
        lib.mdDoc "Server for local large language models"
      );
      listenAddress = lib.mkOption {
        type = types.str;
        default = "127.0.0.1:11434";
        description = lib.mdDoc ''
          Specifies the bind address on which the ollama server HTTP interface listens.
        '';
      };
      acceleration = lib.mkOption {
        type = types.nullOr (types.enum ["rocm" "cuda"]);
        default = null;
        example = "rocm";
        description = lib.mdDoc ''
          Specifies the interface to use for hardware acceleration.

          - `rocm`: supported by modern AMD GPUs
          - `cuda`: supported by modern NVIDIA GPUs
        '';
      };

      logFile = lib.mkOption {
        type = types.path;
        default = null;
        example = "/var/tmp/ollama.log";
        description = lib.mdDoc "The Log file to use for ollama.";
      };

      package = lib.mkPackageOption pkgs "ollama" {};
    };
  };

  config = 
    lib.mkIf cfg.enable {
          launchd.user.agents.ollama = {
          command = "${cfg.package}/bin/ollama serve";
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = cfg.logFile;
            StandardErrorPath = cfg.logFile;
          };
        };
    };

}
