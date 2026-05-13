{ config, lib, ... }:
let cfg = config.modules.ai.hermes-weather; in {
  options.modules.ai.hermes-weather.enable = lib.mkEnableOption ''
    Hermes weather plugin (FahrenheitResearch) — NWS, METAR, Open-Meteo,
    NEXRAD radar, HRRR/NBM/RAP/GFS/GraphCast model imagery & soundings,
    ECAPE, verified meteorological calculations.

    Repo: https://github.com/FahrenheitResearch/hermes-weather-plugin
  '';

  config = lib.mkIf (cfg.enable && config.modules.ai.hermes.enable) {
    # rustplots is a transitive dep of rustweather (a dep of the weather
    # plugin) but isn't on PyPI - only on GitHub. Upstream's pyproject
    # forgets to pin it as a git URL, so we inject it here. Drop this
    # line once FahrenheitResearch publishes rustplots to PyPI.
    modules.ai.hermes.extraPackages = [
      "git+https://github.com/FahrenheitResearch/rustplots.git@master"
      "git+https://github.com/FahrenheitResearch/hermes-weather-plugin"
    ];
  };
}
