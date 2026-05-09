# Nix Restructure — Step 4: Migrate `common/` → `modules/` (Pattern + 4 topics)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Scope decision:** the spec §9 step 4 calls for migrating 18+ topics. Doing all in one autonomous pass is risky. **This plan migrates 4 cleanly-scoped topics — `sops`, `ssh`, `keyboard`, `email` — establishing the pattern. Larger or stateful topics (`browsers/`, `shell/`, `neovim/`, `personal/`, `linux/`, `nvidia/`, `macos/`) are explicitly deferred to follow-up plans.**

**Goal:** Prove the migration pattern with low-risk topics. Each migrated topic becomes an enable-flag-gated module in `modules/{system,home}/<topic>/`, defaults `lib.mkDefault true`, leaves `common/<topic>/default.nix` as a forwarding shim until a later step retires it.

**Verification:** every migrated topic gets `enable = lib.mkDefault true` so behavior is preserved. Closure may differ but every host must evaluate and macbook-neo `darwin-rebuild switch`es cleanly.

**Spec reference:** `docs/superpowers/specs/2026-05-08-nix-config-restructure-design.md` §9 step 4.

---

## Task 1: Pre-flight baseline

- [ ] Confirm clean tree.
- [ ] Capture closures for all 9 hosts → `docs/superpowers/plans/_baselines/step4-baselines.txt` (gitignored).

---

## Task 2: Establish `modules/{system,home}/` index files

- [ ] **`modules/system/default.nix`**:

  ```nix
  { ... }: {
    imports = [
      # Step 4 migrations append here.
    ];
  }
  ```

- [ ] **`modules/home/default.nix`**:

  ```nix
  { ... }: {
    imports = [
      ./ai
      # Step 4 migrations append here.
    ];
  }
  ```

Commit:

```bash
git add modules/system/default.nix modules/home/default.nix
git commit -m "feat(modules): create index default.nix for system & home

Empty umbrellas that subsequent topic-migration commits append to.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Migrate `common/sops/` → `modules/system/sops/`

- [ ] **Step 1: Inspect**

  ```bash
  cat common/sops/default.nix
  ls common/sops/
  ```

- [ ] **Step 2: Create `modules/system/sops/default.nix`**

  Read `common/sops/default.nix`. Then write a new file at `modules/system/sops/default.nix` with this shape:

  ```nix
  { config, lib, pkgs, inputs, ... }:
  let cfg = config.modules.sops; in {
    options.modules.sops.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable sops-nix secret loading";
    };

    config = lib.mkIf cfg.enable {
      # PASTE the body of common/sops/default.nix here.
      # If the original used `let … in { … }`, lift the let bindings to
      # the module's outer let above.
    };
  }
  ```

  Note the default-true so behavior is preserved without explicit profile changes.

- [ ] **Step 3: Add to imports**

  Edit `modules/system/default.nix`:

  ```nix
  { ... }: {
    imports = [
      ./sops
    ];
  }
  ```

- [ ] **Step 4: Replace `common/sops/default.nix` with shim**

  ```nix
  # Migration shim. Real config in modules/system/sops/.
  { ... }: {
    imports = [ ../../modules/system/sops ];
  }
  ```

- [ ] **Step 5: Eval & commit**

  ```bash
  nix eval --raw .#darwinConfigurations.macbook-neo.config.system.build.toplevel.outPath 2>&1 | tail -3

  git add common/sops/ modules/system/sops/ modules/system/default.nix
  git commit -m "refactor(modules/system): migrate sops -> modules/system/sops/

  enable flag defaults true; common/sops/default.nix is now a
  forwarding shim until os/*/home/default.nix is rewired.

  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
  ```

---

## Task 4: Migrate `common/ssh/` → `modules/home/ssh/`

Same pattern as sops, but home layer.

- [ ] Inspect `common/ssh/`.
- [ ] Create `modules/home/ssh/default.nix` with the wrapped config and `options.modules.ssh.enable` (default true).
- [ ] Add `./ssh` to `modules/home/default.nix` imports.
- [ ] Replace `common/ssh/default.nix` with a shim.
- [ ] Eval, commit.

---

## Task 5: Migrate `common/keyboard/` → `modules/{system,home}/keyboard/`

- [ ] Inspect `common/keyboard/` to determine appropriate layer (kanata/keyd → system; XKB user prefs → home).
- [ ] Migrate per the right layer following the pattern.
- [ ] Eval, commit.

---

## Task 6: Migrate `common/email/` → `modules/home/email/`

Email config (`mbsync`, `notmuch`, `aerc`, etc.) is per-user.

- [ ] Inspect, migrate, eval, commit.

---

## Task 7: Verify all 9 hosts evaluate

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

Build the 4 Darwin hosts.

---

## Task 8: Activate macbook-neo

```bash
sudo darwin-rebuild switch --flake .#macbook-neo
```

Smoke test.

---

## Task 9: Final verification

```bash
ls modules/system/ modules/home/
ls common/
git log --oneline -10
git status --short
```

Expected: 4 new entries under modules/{system,home}/, the 4 corresponding common/ topics still exist as shims, clean tree.

---

## Migrations explicitly deferred (write Step 5+ plans)

| Topic | Why deferred |
|-------|--------------|
| `common/browsers/` | Large (zen.nix 372 lines + userscripts dir) |
| `common/shell/` | Has doom/, scripts/, keys/ subtrees |
| `common/editors/` | Cross-platform, multi-editor |
| `common/neovim/` | Tied to editors; consolidation candidate |
| `common/personal/` | Holds the ai shim + prompts/, skills/ |
| `common/linux/` | i3, calibre, koreader, okular, ollama, rofi, tradingview |
| `common/macos/` | hammerspoon, aerospace, xcode etc. |
| `common/nvidia/` | hardware-specific, only frame16/main |
| `common/work/` | tied to mac-work specifically |
| `common/packages/` | flat package list; cross-cutting |
| `common/nixos-config/` | Duplicates os/nixos/; investigate |
| `common/lsp/` | Small but may overlap with editors |
| `common/gaming/` | Linux only |
| `common/vms/` | virt-manager / libvirt; system-layer |
