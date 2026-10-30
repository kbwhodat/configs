{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.omp;
  sys = pkgs.stdenv.hostPlatform.system;
  src = inputs.omp.packages.${sys} or { };
in {
  options.modules.ai.omp.enable = lib.mkEnableOption ''
    oh-my-pi (can1357/oh-my-pi) — batteries-included Pi fork. Binary: `omp`.
    Config lives in ~/.omp, separate from Pi's ~/.pi.
  '';

  config = lib.mkIf (cfg.enable && src ? omp) {
    home.packages = [ src.omp ];
  };
}
