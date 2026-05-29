{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.understand-anything;
  src = inputs.understand-anything;

  # Claude Code reads `.claude-plugin/marketplace.json` at the marketplace
  # root and `.claude-plugin/plugin.json` for the plugin manifest — both
  # live at the repo root, so we point both at `src` directly.

  # opencode (and codex/gemini/pi which share ~/.agents/skills) consume
  # bare skill folders. They live under `understand-anything-plugin/skills`
  # in the upstream repo. Enumerate at eval time so new upstream skills
  # appear automatically after a flake-input bump.
  skillsDir = "${src}/understand-anything-plugin/skills";
  skillNames = builtins.attrNames (
    lib.filterAttrs (_: t: t == "directory") (builtins.readDir skillsDir)
  );
in {
  options.modules.ai.understand-anything.enable =
    lib.mkEnableOption "Understand-Anything (Claude Code marketplace + opencode skills)";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # opencode side: one out-of-store symlink per skill into
      # ~/.agents/skills/<skill>. Matches the per-skill style from
      # install.sh so opencode/codex/gemini/pi all discover them.
      home.file = lib.listToAttrs (map (name: {
        name = ".agents/skills/${name}";
        value.source = config.lib.file.mkOutOfStoreSymlink "${skillsDir}/${name}";
      }) skillNames);
    }

    # Claude Code side: declarative marketplace + plugin install. Gated
    # on claude-code being enabled so this module is harmless on hosts
    # that don't run Claude Code.
    (lib.mkIf config.modules.ai.claude-code.enable {
      programs.claude-code.marketplaces.understand-anything = src;
      programs.claude-code.plugins = [ "${src}/understand-anything-plugin" ];
    })
  ]);
}
