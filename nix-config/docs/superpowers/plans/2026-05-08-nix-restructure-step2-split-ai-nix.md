# Nix Restructure — Step 2: Split `ai.nix`

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decompose `common/personal/ai.nix` (516 lines) into focused single-purpose modules under `modules/home/ai/`, each with its own enable flag. Replace `common/personal/ai.nix` with a thin shim that enables every flag, so all 9 hosts behave identically. Also move `ocvBinary` into `pkgs/by-name/ocv/`.

**Architecture:** Six new files under `modules/home/ai/`, gated by `modules.ai.<thing>.enable`. The umbrella `modules.ai.enable` defaults each leaf to `true`. Activation hooks move to whichever sub-module owns the matching feature. The huge ECC opencode shim JS literal extracts to a sibling `.js` file.

**Tech Stack:** Nix flakes, home-manager, nix-darwin.

**Verification:** closure paths will differ from Step-1 baselines (module graph changes). Acceptable. The realistic check is: every host evaluates, every Apple-Silicon Darwin host builds, macbook-neo `darwin-rebuild switch`es and smoke-tests pass.

**Spec reference:** `docs/superpowers/specs/2026-05-08-nix-config-restructure-design.md` §8.

---

## Task 1: Pre-flight baseline capture

Files: `docs/superpowers/plans/_baselines/step2-baselines.txt` (gitignored).

- [ ] **Step 1: Confirm clean tree** — `git status --short` empty.

- [ ] **Step 2: Capture closures**

  ```bash
  cd /Users/katob/.config/nix-config
  : > docs/superpowers/plans/_baselines/step2-baselines.txt
  for h in frame13 frame16 main server util; do
    p=$(nix eval --raw .#nixosConfigurations.$h.config.system.build.toplevel.outPath 2>/dev/null)
    echo "$h  $p" >> docs/superpowers/plans/_baselines/step2-baselines.txt
  done
  for h in mac-personal mac-studio mac-work macbook-neo; do
    p=$(nix eval --raw .#darwinConfigurations.$h.config.system.build.toplevel.outPath 2>/dev/null)
    echo "$h  $p" >> docs/superpowers/plans/_baselines/step2-baselines.txt
  done
  cat docs/superpowers/plans/_baselines/step2-baselines.txt
  ```

  Expected: 9 lines. If errors, STOP. No commit (gitignored).

---

## Task 2: Move `ocvBinary` to `pkgs/by-name/ocv/`

- [ ] **Step 1:** Inspect `pkgs/overlay.nix` to confirm `pkgs/by-name/` auto-discovery.

- [ ] **Step 2:** Create `pkgs/by-name/ocv/default.nix`:

  ```nix
  { lib, stdenv, stdenvNoCC, fetchurl, autoPatchelfHook }:
  let
    ocvRelease = "v1.14.25-ocv.3.28";
    ocvAssets = {
      "aarch64-darwin" = { asset = "ocv-darwin-arm64"; sha256 = "d81f5a159dffc5126aa861385ed105adf7420f1e299ca32529c4a33d06d448a8"; };
      "x86_64-darwin"  = { asset = "ocv-darwin-x64";   sha256 = "72a78491aaa621f6ef47d09a6a8f9d322e69a5dab505250246a4354b00d8cb1a"; };
      "aarch64-linux"  = { asset = "ocv-linux-arm64";  sha256 = "b3f6bbe99d6fb9c5a74c76f6489dea8636e3b8c07826956469c2580494eb56d0"; };
      "x86_64-linux"   = { asset = "ocv-linux-x64";    sha256 = "338c89d95bada61965fed79099360ce853b8875522805c0bbe19f20beff152e7"; };
    };
    a = ocvAssets.${stdenv.hostPlatform.system}
      or (throw "ocv: unsupported system ${stdenv.hostPlatform.system}");
  in
  stdenvNoCC.mkDerivation {
    pname = "ocv";
    version = lib.removePrefix "v" ocvRelease;
    src = fetchurl {
      url = "https://github.com/leohenon/opencode-vim/releases/download/${ocvRelease}/${a.asset}";
      sha256 = a.sha256;
    };
    dontUnpack = true;
    nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
    buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];
    installPhase = ''
      mkdir -p $out/bin
      install -m755 $src $out/bin/opencode
    '';
    meta = with lib; {
      description = "Prebuilt opencode-vim binary";
      mainProgram = "opencode";
      platforms = lib.attrNames ocvAssets;
    };
  }
  ```

- [ ] **Step 3: Verify** — `nix build --no-link --print-out-paths .#ocv 2>&1 | tail -3`. Expected: a store path. If "attribute 'ocv' missing", overlay isn't auto-discovering — report DONE_WITH_CONCERNS.

- [ ] **Step 4: Commit**

  ```bash
  git add pkgs/by-name/ocv/ && git commit -m "feat(pkgs): extract ocv (opencode-vim) into pkgs/by-name/

  Lifted the inline ocvBinary derivation out of common/personal/ai.nix.

  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
  ```

---

## Task 3: Create `modules/home/ai/default.nix` (umbrella)

```nix
{ config, lib, ... }:
let cfg = config.modules.ai; in {
  imports = [
    ./mcp-servers.nix
    ./rtk.nix
    ./jobdrop.nix
    ./claude-code.nix
    ./opencode.nix
  ];

  options.modules.ai.enable = lib.mkEnableOption "AI tooling umbrella";

  config = lib.mkIf cfg.enable {
    modules.ai.claude-code.enable = lib.mkDefault true;
    modules.ai.opencode.enable    = lib.mkDefault true;
    modules.ai.mcp-servers.enable = lib.mkDefault true;
    modules.ai.rtk.enable         = lib.mkDefault true;
    modules.ai.jobdrop.enable     = lib.mkDefault true;
  };
}
```

No commit yet (siblings don't exist; commit comes after Task 9).

---

## Task 4: Create `modules/home/ai/mcp-servers.nix`

```nix
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.mcp-servers;
  system = pkgs.stdenv.hostPlatform.system;
in {
  options.modules.ai.mcp-servers.enable = lib.mkEnableOption "MCP server packages";

  config = lib.mkIf cfg.enable {
    home.packages =
      (with inputs.mcp-servers-nix.packages.${system}; [
        context7-mcp
        mcp-server-fetch
        mcp-server-sequential-thinking
        serena
      ])
      ++ (with pkgs; [
        mcp-nixos
        terraform-mcp-server
        playwright-mcp
      ]);
  };
}
```

---

## Task 5: Create `modules/home/ai/rtk.nix`

```nix
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.rtk;
  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  opencodeDir = "${config.home.homeDirectory}/.config/opencode";
  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";
in {
  options.modules.ai.rtk.enable = lib.mkEnableOption "RTK CLI proxy + plugins";

  config = lib.mkIf cfg.enable {
    home.packages = [ unstable.rtk ];

    home.activation.installRtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "${opencodeDir}/plugins/rtk.ts" ]; then
        ${unstable.rtk}/bin/rtk init -g --opencode --auto-patch 2>/dev/null || true
      fi
    '';

    home.activation.installRtkClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${claudeHookPath}" ]; then
        ${unstable.rtk}/bin/rtk init -g --hook-only --no-patch 2>/dev/null || true
      fi
    '';
  };
}
```

---

## Task 6: Create `modules/home/ai/jobdrop.nix`

```nix
{ config, lib, pkgs, ... }:
let cfg = config.modules.ai.jobdrop; in {
  options.modules.ai.jobdrop.enable = lib.mkEnableOption "jobdrop MCP server";

  config = lib.mkIf cfg.enable {
    home.activation.installJobdrop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server" ]; then
        echo "[installJobdrop] installing jobdrop[mcp] via uv tool…"
        if ! PATH="${pkgs.uv}/bin:$PATH" ${pkgs.uv}/bin/uv tool install "jobdrop[mcp]"; then
          echo "[installJobdrop] WARNING: uv tool install failed — run manually: uv tool install 'jobdrop[mcp]'" >&2
        fi
      fi
    '';
  };
}
```

---

## Task 7: Extract ECC opencode shim → `modules/home/ai/ecc-opencode-shim.js`

Verbatim extraction of the JS body from the existing `patchEccPlugin` heredoc (`common/personal/ai.nix:121-186`).

```javascript
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const eccSkillsDir = path.resolve(__dirname, "skills");
const eccOpenCodeDir = path.resolve(__dirname, ".opencode");

function loadEccConfig() {
  const configPath = path.join(eccOpenCodeDir, "opencode.json");
  if (!fs.existsSync(configPath)) return null;
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function resolveFileRefs(obj, baseDir) {
  if (typeof obj === "string") {
    const match = obj.match(/^\{file:(.+)\}$/);
    if (match) {
      const filePath = path.join(baseDir, match[1]);
      if (fs.existsSync(filePath)) return fs.readFileSync(filePath, "utf8");
    }
    return obj;
  }
  if (Array.isArray(obj)) return obj.map(v => resolveFileRefs(v, baseDir));
  if (obj && typeof obj === "object") {
    const out = {};
    for (const [k, v] of Object.entries(obj)) out[k] = resolveFileRefs(v, baseDir);
    return out;
  }
  return obj;
}

export default async ({ client, directory }) => {
  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (fs.existsSync(eccSkillsDir) && !config.skills.paths.includes(eccSkillsDir)) {
        config.skills.paths.push(eccSkillsDir);
      }

      const ecc = loadEccConfig();
      if (!ecc) return;

      if (ecc.agent) {
        config.agent = config.agent || {};
        for (const [name, def] of Object.entries(ecc.agent)) {
          if (name === "build") {
            config.agent["ecc-build"] = resolveFileRefs(def, eccOpenCodeDir);
          } else if (!config.agent[name]) {
            config.agent[name] = resolveFileRefs(def, eccOpenCodeDir);
          }
        }
      }

      if (ecc.command) {
        config.command = config.command || {};
        for (const [name, def] of Object.entries(ecc.command)) {
          if (!config.command[name]) {
            config.command[name] = resolveFileRefs(def, eccOpenCodeDir);
          }
        }
      }
    },
  };
};
```

---

## Task 8: Create `modules/home/ai/opencode.nix`

Largest leaf — wraps `programs.opencode` and `patchEccPlugin`. Uses `pkgs.ocv` and `${./ecc-opencode-shim.js}`.

```nix
{ config, lib, pkgs, inputs, ... }:
let cfg = config.modules.ai.opencode; in {
  options.modules.ai.opencode.enable = lib.mkEnableOption "opencode TUI + ECC patch hook";

  config = lib.mkIf cfg.enable {
    home.activation.patchEccPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ECC_PKG_DIR="${config.home.homeDirectory}/.cache/opencode/packages/ecc-universal@git+https:/github.com/affaan-m/everything-claude-code.git/node_modules/ecc-universal"
      ECC_HOISTED_DIR="${config.home.homeDirectory}/.cache/opencode/node_modules/ecc-universal"
      for ECC_DIR in "$ECC_PKG_DIR" "$ECC_HOISTED_DIR"; do
        if [ -d "$ECC_DIR" ]; then
          install -m644 ${./ecc-opencode-shim.js} "$ECC_DIR/ecc-opencode-shim.js"
          ${pkgs.python3}/bin/python3 -c "
      import json
      p = '$ECC_DIR/package.json'
      with open(p) as f: d = json.load(f)
      if d.get('main') != 'ecc-opencode-shim.js':
          d['main'] = 'ecc-opencode-shim.js'
          with open(p, 'w') as f: json.dump(d, f, indent=2)
      "
        fi
      done
    '';

    programs.opencode = {
      enable = true;
      package = pkgs.ocv;
      enableMcpIntegration = true;
      context = ''
        Do not use AskUserQuestion — that tool does not exist here. To ask the user a question, use the "question" tool instead.
      '';
      commands = {
        rebuild-switch = ''
          Rebuild and switch to NixOS flake configuration defined for current machine.
          Usage: /rebuild-switch
        '';
      };
      skills = {};
      tui.keybinds = {
        messages_half_page_up = "ctrl+alt+u";
        messages_half_page_down = "ctrl+alt+d";
        messages_line_up = "ctrl+alt+y";
        messages_line_down = "ctrl+alt+e";
      };
      settings = {
        plugin = [
          "superpowers@git+https://github.com/obra/superpowers.git"
          "ecc-universal@git+https://github.com/affaan-m/everything-claude-code.git"
        ];
        mcp = {
          context7 = { type = "remote"; url = "https://mcp.context7.com/mcp"; enabled = false; };
          mcp_nixos = { type = "local"; command = [ "mcp-nixos" ]; enabled = false; };
          terraform = { type = "local"; command = [ "terraform-mcp-server" ]; enabled = false; };
          fetch = { type = "local"; command = [ "mcp-server-fetch" ]; enabled = false; };
          firecrawl = { type = "local"; command = [ "env" "FIRECRAWL_API_KEY=fc-b5db7738ea3843dd86181be770891120" "npx" "-y" "firecrawl-mcp" ]; enabled = true; };
          playwright = { type = "local"; command = [ "mcp-server-playwright" "--no-sandbox" ]; enabled = true; };
          sequential_thinking = { type = "local"; command = [ "mcp-server-sequential-thinking" ]; enabled = false; };
          serena = { type = "local"; command = [ "serena" "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ]; enabled = true; };
          jcodemunch = { type = "local"; command = [ "jcodemunch" ]; enabled = false; };
          jobdrop = { type = "local"; command = [ "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server" ]; enabled = true; };
        };
        autoshare = false;
        autoupdate = false;
        permission = {
          webfetch = "allow";
          grep = "allow";
          read = "allow";
          zsh = { "*" = "allow"; "rm*" = "ask"; "rmdir*" = "ask"; "unlink*" = "ask"; "mv*" = "ask"; "sudo*" = "deny"; };
          bash = { "*" = "allow"; "rm*" = "ask"; "rmdir*" = "ask"; "unlink*" = "ask"; "mv*" = "ask"; "sudo*" = "deny"; };
        };
        agent = {
          perftutor = {
            mode = "primary";
            description = "Perf Tutor Agent";
            prompt = builtins.readFile ../../../common/personal/prompts/perftutor.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            temperature = 0.25;
          };
          perfguru = {
            mode = "primary";
            description = "Perf Guru Agent";
            prompt = builtins.readFile ../../../common/personal/prompts/perfguru.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            temperature = 0.25;
          };
          planner = {
            mode = "subagent";
            description = "Expert planning specialist for complex features and refactoring";
            prompt = builtins.readFile ../../../common/personal/prompts/planner.txt;
            tools = { read = true; bash = true; };
          };
          tdd-guide = {
            mode = "subagent";
            description = "TDD specialist enforcing test-first development with Red-Green-Refactor";
            prompt = builtins.readFile ../../../common/personal/prompts/tdd-guide.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
          };
        };
      };
    };
  };
}
```

Critical: prompt-text paths now `../../../common/personal/prompts/` (three `..`).

---

## Task 9: Create `modules/home/ai/claude-code.nix` and commit all 6 modules

```nix
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.ai.claude-code;
  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";

  eccSrc = pkgs.fetchFromGitHub {
    owner = "affaan-m";
    repo = "everything-claude-code";
    rev = "main";
    sha256 = "sha256-R1LwfU8w4QJi69so+TG1BMVVH+zf9epsAmZPbw9mnYU=";
  };
  superpowersSrc = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "main";
    sha256 = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
  };
in {
  options.modules.ai.claude-code.enable = lib.mkEnableOption "Claude Code with ECC + superpowers";

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = unstable.claude-code;
      marketplaces = { ecc = eccSrc; superpowers = superpowersSrc; };
      plugins = [ eccSrc superpowersSrc ];
      mcpServers = {
        context7 = { url = "https://mcp.context7.com/mcp"; disabled = true; };
        mcp_nixos = { command = "mcp-nixos"; disabled = true; };
        terraform = { command = "terraform-mcp-server"; disabled = true; };
        fetch = { command = "mcp-server-fetch"; disabled = true; };
        firecrawl = {
          command = "env";
          args = [ "FIRECRAWL_API_KEY=fc-b5db7738ea3843dd86181be770891120" "npx" "-y" "firecrawl-mcp" ];
        };
        playwright = { command = "mcp-server-playwright"; args = [ "--no-sandbox" ]; };
        sequential_thinking = { command = "mcp-server-sequential-thinking"; disabled = true; };
        serena = {
          command = "serena";
          args = [ "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ];
        };
        jcodemunch = { command = "jcodemunch"; disabled = true; };
        jobdrop = { command = "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server"; };
      };
      settings = {
        hooks.PreToolUse = [
          {
            matcher = "Bash";
            hooks = [ { type = "command"; command = claudeHookPath; } ];
          }
        ];
        permissions = {
          allow = [ "WebFetch" "Read" "Grep" "Bash" "Zsh" ];
          deny = [ "Bash(sudo*)" "Zsh(sudo*)" ];
          ask = [ "Bash(rm*)" "Bash(rmdir*)" "Bash(unlink*)" "Bash(mv*)"
                  "Zsh(rm*)" "Zsh(rmdir*)" "Zsh(unlink*)" "Zsh(mv*)" ];
        };
      };
    };
  };
}
```

After all 6 Nix files + 1 JS file exist:

```bash
cd /Users/katob/.config/nix-config
for f in modules/home/ai/default.nix modules/home/ai/mcp-servers.nix modules/home/ai/rtk.nix modules/home/ai/jobdrop.nix modules/home/ai/opencode.nix modules/home/ai/claude-code.nix; do
  nix-instantiate --parse "$f" > /dev/null && echo "$f  OK" || echo "$f  FAIL"
done

git add modules/home/ai/
git commit -m "feat(modules/home/ai): split ai.nix into focused enable-flag modules

Six leaf modules under modules/home/ai/, each gated by its own
modules.ai.<thing>.enable flag. The umbrella modules.ai.enable
defaults every leaf to true.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Replace `common/personal/ai.nix` with shim

Overwrite `common/personal/ai.nix` with:

```nix
# Compatibility shim during the Step 2 migration:
# the real config lives under modules/home/ai/. Step 4 deletes this file.
{ ... }: {
  imports = [
    ../../modules/home/ai
  ];

  modules.ai.enable = true;
}
```

Then verify and commit:

```bash
nix eval --raw .#darwinConfigurations.macbook-neo.config.system.build.toplevel.outPath 2>&1 | tail -5
nix build --no-link --print-out-paths .#darwinConfigurations.macbook-neo.config.system.build.toplevel 2>&1 | tail -3

git add common/personal/ai.nix
git commit -m "refactor(common/personal): replace ai.nix with shim into modules/home/ai

516-line monolith collapses to a 10-line forwarding module.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Verify all 9 hosts evaluate

```bash
for h in frame13 frame16 main server util; do
  p=$(nix eval --raw .#nixosConfigurations.$h.config.system.build.toplevel.outPath 2>&1 | tail -1)
  case "$p" in /nix/store/*) echo "$h  OK" ;; *) echo "$h  FAIL  $p" ;; esac
done
for h in mac-personal mac-studio mac-work macbook-neo; do
  p=$(nix eval --raw .#darwinConfigurations.$h.config.system.build.toplevel.outPath 2>&1 | tail -1)
  case "$p" in /nix/store/*) echo "$h  OK" ;; *) echo "$h  FAIL  $p" ;; esac
done
```

Then build the 4 Apple-Silicon Darwin hosts:

```bash
for h in mac-personal mac-studio mac-work macbook-neo; do
  echo "=== $h ==="
  nix build --no-link --print-out-paths .#darwinConfigurations.$h.config.system.build.toplevel 2>&1 | tail -3
done
```

---

## Task 12: Activate macbook-neo

```bash
sudo darwin-rebuild switch --flake .#macbook-neo
```

Smoke test:

```bash
echo "== hostname =="; hostname
echo "== Hammerspoon =="; pgrep -lf Hammerspoon | head -1
echo "== Claude plugin data =="; ls ~/.claude/plugins/data/
echo "== jobdrop =="; test -x ~/.local/bin/jobdrop-mcp-server && echo OK || echo MISSING
echo "== opencode =="; which opencode
echo "== rtk =="; which rtk
```

---

## Task 13: Final verification

```bash
ls modules/home/ai/
wc -l common/personal/ai.nix
ls pkgs/by-name/ocv/
git log --oneline -8
git status --short
```

Expected: 7 files in modules/home/ai/, ai.nix ≤15 lines, ocv/default.nix exists, clean tree.

---

## What this leaves for Step 3

`modules/home/ai/` is canonical. Step 3 (profiles) moves the umbrella toggle into `profiles/home/workstation.nix` so server hosts can omit AI tooling.
