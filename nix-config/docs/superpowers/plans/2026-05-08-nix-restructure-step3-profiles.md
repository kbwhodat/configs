# Nix Restructure — Step 3: Profiles Scaffolding

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `profiles/` directory tree with `profiles/system/` and `profiles/home/` populated by name (`base`, `desktop`, `laptop`, `workstation`, `server`, `work`, `gaming`). Wire each of the 9 hosts to its appropriate profile list via the `mkHost` / `mkDarwin` factory's `profiles` argument. Profile bodies are intentionally **scaffolding** in Step 3 — they declare and toggle `modules.*.enable` flags but defer the heavy lifting (importing actual feature config) to Step 4 when `common/` is migrated.

**Architecture:** The factory's `resolveProfiles` (already in `lib/default.nix` since Step 1) looks up `profiles/<layer>/<name>.nix`. Profiles only flip enable-flags. After Step 3, the host inventory per spec §7 is reflected in `flake.nix` via `profiles = [ … ]`; the host wrapper files (`hosts/<name>/system.nix` / `home.nix`) remain thin until Step 4 retires them.

**Verification model:** profile bodies are mostly empty enable-flag toggles, so the closure should be unchanged or trivially different. Acceptance: every host evaluates and macbook-neo `darwin-rebuild switch`es cleanly.

**Spec reference:** `docs/superpowers/specs/2026-05-08-nix-config-restructure-design.md` §4.1, §4.3, §6, §7, §9 step 3.

---

## Task 1: Pre-flight baseline

- [ ] Confirm clean tree.
- [ ] Capture closures for all 9 hosts into `docs/superpowers/plans/_baselines/step3-baselines.txt` (gitignored). Same pattern as Step 1/2 baselines.

---

## Task 2: Create `profiles/system/` skeleton

Each file body:

```nix
{ ... }: {
  # Step 3 scaffolding. Populated in Step 4 when common/* is migrated.
}
```

- [ ] `profiles/system/base.nix`
- [ ] `profiles/system/desktop.nix`
- [ ] `profiles/system/laptop.nix`
- [ ] `profiles/system/server.nix`
- [ ] `profiles/system/work.nix`

Note: `gaming` and `workstation` don't have a system-layer file. `resolveProfiles` silently skips missing layer files.

---

## Task 3: Create `profiles/home/` skeleton

Most files use the empty-body template above.

`profiles/home/workstation.nix` is non-empty:

```nix
{ ... }: {
  # Step 3: declare AI-tooling intent at the profile layer.
  # Today this is moot — common/personal/ai.nix shim already enables
  # modules.ai.enable globally. After Step 4 removes the shim, this
  # profile becomes the single source of truth for AI-on hosts.
  modules.ai.enable = true;
}
```

`profiles/home/server.nix`:

```nix
{ lib, ... }: {
  # Server hosts are headless; force AI tooling off so the umbrella
  # cannot accidentally land on them via the shim.
  modules.ai.enable = lib.mkForce false;
}
```

- [ ] `profiles/home/base.nix` (empty body)
- [ ] `profiles/home/desktop.nix` (empty body)
- [ ] `profiles/home/laptop.nix` (empty body)
- [ ] `profiles/home/workstation.nix` (sets `modules.ai.enable = true`)
- [ ] `profiles/home/server.nix` (forces `modules.ai.enable = false`)
- [ ] `profiles/home/work.nix` (empty body)
- [ ] `profiles/home/gaming.nix` (empty body)

Commit:

```bash
git add profiles/
git commit -m "feat(profiles): scaffold profiles/{system,home}/

Empty placeholders that resolveProfiles can find. Step 4 fills them
once common/ is migrated. profiles/home/{workstation,server}.nix are
the only non-empty bodies — they declare intent for AI tooling per
host role.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Wire profiles through `flake.nix`

Per spec §7 host inventory, add `profiles = [ … ]` to each factory call:

| Host | Profile list |
|------|--------------|
| frame13 | `[ "base" "desktop" "laptop" "workstation" ]` |
| frame16 | `[ "base" "desktop" "laptop" "workstation" "gaming" ]` |
| main | `[ "base" "desktop" "workstation" "gaming" ]` |
| server | `[ "base" "server" ]` |
| util | `[ "base" "server" ]` |
| mac-personal | `[ "base" "desktop" "workstation" ]` |
| mac-studio | `[ "base" "desktop" "workstation" ]` |
| macbook-neo | `[ "base" "desktop" "workstation" ]` |
| mac-work | `[ "base" "desktop" "workstation" "work" ]` |

Example for frame13:

```nix
        frame13 = mkHost {
          hostname = "frame13";
          system = "x86_64-linux";
          systemPath = ./os/nixos/hosts/frame13/configuration.nix;
          homePath = ./os/nixos/hosts/frame13/home/default.nix;
          profiles = [ "base" "desktop" "laptop" "workstation" ];
          extraModules = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
        };
```

(Leave `systemPath`/`homePath` bypasses in place — Step 4 retires them when wrappers absorb the work.)

Eval each host. Commit:

```bash
git add flake.nix
git commit -m "feat(flake): wire host profile lists through factory

Per spec §7 host inventory. Bodies are mostly empty in Step 3 so
this is a no-op semantically; it puts wiring in place for Step 4.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Verify all 9 hosts evaluate

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

Expected: 9 OK.

Build the 4 Apple-Silicon Darwin hosts:

```bash
for h in mac-personal mac-studio mac-work macbook-neo; do
  echo "=== $h ==="
  nix build --no-link --print-out-paths .#darwinConfigurations.$h.config.system.build.toplevel 2>&1 | tail -3
done
```

---

## Task 6: Activate macbook-neo

```bash
sudo darwin-rebuild switch --flake .#macbook-neo
```

Smoke test (hostname, Hammerspoon, Claude plugins, jobdrop, opencode, rtk).

---

## Task 7: Final verification

```bash
ls profiles/system/ profiles/home/
git log --oneline -5
git status --short
wc -l flake.nix
```

Expected: 5 system profiles + 7 home profiles, clean tree.

---

## What this leaves for Step 4

`profiles/` exists but bodies are mostly empty. `common/` and `os/` are still canonical. Step 4 migrates `common/<topic>/` → `modules/{system,home}/<topic>/`, populates profile bodies, and retires the `systemPath`/`homePath` bypasses.
