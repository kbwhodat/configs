{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.pi-coding-agent;

  # Plugin sources come from flake inputs (see flake.nix) and are
  # shared with claude-code.nix — Pi implements the same Agent Skills
  # standard, so we can symlink the same skill dirs into Pi's
  # auto-discovery path. Bumps happen via
  # `nix flake update --update-input <name>`.
  eccSrc         = inputs.everything-claude-code;
  superpowersSrc = inputs.superpowers;
in {
  options.modules.ai.pi-coding-agent = {
    enable = lib.mkEnableOption ''
      Pi coding agent (badlogic/pi-mono) — minimal coding-agent CLI.
      Currently installed via `npm install -g` at activation (not via
      the kissgyorgy flake) because the flake's Pi v0.74.0 build is
      broken upstream (lockfile has `resolved: null` entries for
      undici-types). Switch back to the flake once that's fixed.
      Binary: `pi` (in `~/.local/bin`).
    '';

    package = lib.mkOption {
      type = lib.types.str;
      default = "@earendil-works/pi-coding-agent@latest";
      example = "@earendil-works/pi-coding-agent@0.74.0";
      description = ''
        npm spec for Pi itself. Installed via `npm install -g` at
        home-manager activation. `@latest` tracks the newest published
        version; pin to a specific version for reproducibility.
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "npm:pi-kimi-coder"
        "npm:pi-web-access"
        "npm:pi-skillful"
        "npm:pi-subagents"
        "npm:pi-mcp-adapter"
        "npm:pi-context-tools"
        "npm:@samfp/pi-memory"
        "npm:pi-rtk-optimizer"
        "npm:pi-co-authored-by"
        "npm:@howaboua/pi-markdown-workflows"
        "npm:pi-verbosity-control"
        "npm:pi-diff-review"
        "npm:@howaboua/pi-subagent-review"
        "npm:@siddr/pi-openai-params"
        "npm:@howaboua/pi-auto-trees"
        "npm:@howaboua/pi-semantic-grep"
        "npm:@howaboua/pi-vent"
        "npm:pi-codex-goal"
        "npm:pi-lean-ctx"
        "npm:@baggiiiie/pi-no-ansi"
        # "npm:@howaboua/pi-codex-conversion" # tool "web_search" conflicts with pi-web-access; pick one
      ];
      example = [ "npm:pi-kimi-coder" "git:github.com/user/repo@v1" ];
      description = ''
        Pi packages/extensions to ensure installed at activation.
        Each entry is passed verbatim to `pi install`. Idempotent —
        the script greps `~/.pi/agent/settings.json` for the entry
        before invoking, so re-runs only install missing packages.
      '';
    };

    skillSources = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        superpowers = "${superpowersSrc}/skills";
        everything-claude-code = "${eccSrc}/skills";
      };
      description = ''
        Skill directories to surface to Pi. Each `name = path` entry
        becomes a symlink at `~/.pi/agent/skills/<name>` pointing at
        <path>. Pi auto-discovers any directory containing SKILL.md
        recursively, and only descriptions sit in context — so
        surfacing entire plugin skill libraries is cheap.

        Default surfaces both Claude Code plugins (superpowers, ECC)
        since Pi implements the same Agent Skills standard.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # `lean-ctx` is the CLI that `pi-lean-ctx` (the npm extension) shells
    # out to for 60–90% token-saving compression on bash/read/grep/find/ls.
    # The npm extension alone doesn't install the binary.
    home.packages = [ pkgs.lean-ctx ];

    # Skills live at ~/.pi/agent/skills/<name> as out-of-store symlinks
    # so upstream skill updates (after a flake bump) take effect without
    # rebuilding home-manager.
    home.file = lib.mapAttrs' (name: src:
      lib.nameValuePair ".pi/agent/skills/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink src;
      }
    ) cfg.skillSources;

    # npm global prefix → ~/.local (writable, on PATH via the AI umbrella).
    home.sessionVariables.NPM_CONFIG_PREFIX = "$HOME/.local";

    home.activation.installPi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.nodejs_22}/bin:$PATH"
      export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.local"
      mkdir -p "$NPM_CONFIG_PREFIX/bin" "$NPM_CONFIG_PREFIX/lib"
      pi_bin="$NPM_CONFIG_PREFIX/bin/pi"

      # Install (or update) Pi itself. `@latest` always reinstalls — we
      # gate on absence to keep the steady-state idempotent; bump version
      # by setting `modules.ai.pi-coding-agent.package` to a pinned spec
      # or removing the binary manually to force a fresh install.
      if [ ! -x "$pi_bin" ]; then
        echo "[pi] installing ${cfg.package}…"
        ${pkgs.nodejs_22}/bin/npm install -g '${cfg.package}' \
          || echo "[pi] WARNING: failed to install ${cfg.package}" >&2
      fi

      if [ ! -x "$pi_bin" ]; then
        echo "[pi] skipping extension install — pi binary not found at $pi_bin" >&2
        exit 0
      fi

      settings_file="${config.home.homeDirectory}/.pi/agent/settings.json"
      ${lib.concatMapStringsSep "\n" (ext: ''
        if ! grep -Fq '"${ext}"' "$settings_file" 2>/dev/null; then
          echo "[pi] installing extension ${ext}"
          "$pi_bin" install '${ext}' \
            || echo "[pi] WARNING: failed to install ${ext}" >&2
        fi
      '') cfg.extensions}
    '';
  };
}
