{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.librarian;
  src = inputs.librarian;

  # Runtime deps pulled in via `uv run --with`. uv caches the env after
  # the first call. Kept here so a flake bump that changes the
  # pyproject.toml dependency set is a one-file edit. Pin floors match
  # the upstream pyproject.toml.
  pyDeps = [
    "fastembed>=0.4.0"
    "lancedb>=0.15.0"
    "pyyaml>=6.0"
    "pymupdf>=1.24.0"
    "requests>=2.31.0"
    "beautifulsoup4>=4.12.0"
    "markdownify>=0.13.0"
    "feedparser>=6.0.0"
  ];
  withArgs = lib.concatMapStringsSep " " (d: "--with '${d}'") pyDeps;

  # Single shim that replaces every `python3 …/scripts/foo.py` call
  # in the upstream command/skill markdown. We rewrite those lines
  # below to invoke this binary instead.
  librarianPy = pkgs.writeShellScriptBin "librarian-py" ''
    exec ${pkgs.uv}/bin/uv run --quiet ${withArgs} python3 "$@"
  '';

  # The upstream command file uses `python3 ''${CLAUDE_PLUGIN_ROOT}/scripts/X.py`,
  # which only resolves when Claude Code installs the file as part of a
  # plugin. We're installing the skill/command directly (no plugin
  # marketplace), so the env var would be unset — substitute it out
  # at build time and route python through the uv shim above.
  processed = pkgs.runCommand "librarian-claude-files" { } ''
    mkdir -p $out/commands $out/skills
    cp -r ${src}/skills/library-knowledge $out/skills/library-knowledge
    cp ${src}/commands/library.md $out/commands/library.md
    chmod -R +w $out
    find $out -name '*.md' -exec sed -i \
      -e 's|python3 ''${CLAUDE_PLUGIN_ROOT}|librarian-py ${src}|g' \
      -e 's|''${CLAUDE_PLUGIN_ROOT}|${src}|g' \
      {} +
  '';
in {
  options.modules.ai.librarian.enable =
    lib.mkEnableOption "Librarian — local-first personal knowledge layer (Claude Code + opencode)";

  config = lib.mkIf cfg.enable {
    home.packages = [ librarianPy ];

    home.file = {
      # Claude Code: direct skill + command install (no marketplace —
      # upstream ships only `.claude-plugin/plugin.json`, no
      # marketplace.json, so the plugin schema doesn't apply).
      ".claude/skills/library-knowledge".source =
        config.lib.file.mkOutOfStoreSymlink "${processed}/skills/library-knowledge";
      ".claude/commands/library.md".source =
        config.lib.file.mkOutOfStoreSymlink "${processed}/commands/library.md";

      # opencode / codex / gemini / pi share ~/.agents/skills/.
      ".agents/skills/library-knowledge".source =
        config.lib.file.mkOutOfStoreSymlink "${processed}/skills/library-knowledge";
    };
  };
}
