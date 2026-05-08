# Nix Restructure — Step 1: Factory + macbook-neo

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `lib/default.nix` with `mkHost` and `mkDarwin` factory functions, convert all 8 existing hosts to use them, and add a 9th host `macbook-neo`. After Step 1, every host still uses its existing config files — only the `flake.nix` boilerplate is replaced.

**Architecture:** Thin wrapper files in `hosts/<name>/{system,home}.nix` import the existing per-host config. The factory in `lib/default.nix` consolidates the duplicated `nixosSystem`/`darwinSystem` blocks. No file under `os/` or `common/` moves yet; that's Steps 2-5.

**Tech Stack:** Nix flakes, home-manager (NixOS/Darwin module mode), nix-darwin.

**Verification model:** every host conversion must produce the **same store path** for `system.build.toplevel` before and after the change (except hostname-derived bits, which are explicit in `networking.hostName`). New host `macbook-neo` is the exception — it's a fresh build, no baseline.

**Spec reference:** `docs/superpowers/specs/2026-05-08-nix-config-restructure-design.md`

---

## Task 1: Pre-flight — clean working tree and capture baselines

**Files:**
- Read-only: all current `flake.nix`, `os/`, `common/` files
- Create: `docs/superpowers/plans/_baselines/step1-baselines.txt` (gitignored)

- [ ] **Step 1: Confirm working tree state**

Run: `git status --short`

Expected: there are uncommitted changes from the prior session (`common/browsers/zen.nix`, `common/personal/ai.nix`, `flake.nix`, etc.). Either commit them (`git add <paths> && git commit`) or stash them (`git stash push -u -m "pre-step1-stash"`) before proceeding. Don't mix them with the migration commits.

- [ ] **Step 2: Verify all 8 hosts evaluate today**

Run for each host:
```bash
mkdir -p docs/superpowers/plans/_baselines
echo "" > docs/superpowers/plans/_baselines/step1-baselines.txt
for host in frame13 frame16 main server util; do
  path=$(nix eval --raw .#nixosConfigurations.$host.config.system.build.toplevel.outPath 2>&1)
  echo "$host  $path" >> docs/superpowers/plans/_baselines/step1-baselines.txt
done
for host in mac-personal mac-studio mac-work; do
  path=$(nix eval --raw .#darwinConfigurations.$host.config.system.build.toplevel.outPath 2>&1)
  echo "$host  $path" >> docs/superpowers/plans/_baselines/step1-baselines.txt
done
cat docs/superpowers/plans/_baselines/step1-baselines.txt
```

Expected: 8 lines, each a real `/nix/store/<hash>-...` path. If any host errors, **stop** — fix that host's current config first; don't proceed to refactor a broken host.

- [ ] **Step 3: Add baseline file to .gitignore**

Edit `.gitignore` — add line `docs/superpowers/plans/_baselines/`. Saves the file from accidental commits.

- [ ] **Step 4: Commit the .gitignore change**

```bash
git add .gitignore
git commit -m "chore: gitignore plan baselines directory"
```

---

## Task 2: Create `lib/default.nix` with factories

**Files:**
- Create: `lib/default.nix`

- [ ] **Step 1: Create the lib directory and factory file**

Create `lib/default.nix` with this exact content:

```nix
{ inputs, overlays }:
let
  # Resolve a profile name into the file that exists at the given layer
  # ("system" or "home"), or null if no file exists. Used by the factories
  # below. Profiles are not yet populated in Step 1, but the signature is
  # in place so Step 3 doesn't need to change the factory.
  profilePath = layer: name:
    let p = ../profiles + "/${layer}/${name}.nix";
    in if builtins.pathExists p then p else null;

  resolveProfiles = layer: profiles:
    builtins.filter (p: p != null) (map (profilePath layer) profiles);

  mkHost = {
    hostname,
    system,
    profiles ? [],
    extraModules ? [],
    homePath ? ../hosts + "/${hostname}/home.nix",
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        (../hosts + "/${hostname}/system.nix")
        inputs.home-manager.nixosModules.home-manager
        {
          networking.hostName = hostname;
          nixpkgs.overlays = overlays;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostname; };
            users.katob.imports = [ homePath ] ++ resolveProfiles "home" profiles;
            backupFileExtension = "backup";
          };
        }
      ] ++ resolveProfiles "system" profiles
        ++ extraModules;
    };

  mkDarwin = {
    hostname,
    system,
    profiles ? [],
    extraModules ? [],
    homePath ? ../hosts + "/${hostname}/home.nix",
  }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        (../hosts + "/${hostname}/system.nix")
        inputs.home-manager.darwinModules.home-manager
        {
          nixpkgs.overlays = overlays;
          users.users.katob = { name = "katob"; home = "/Users/katob"; };
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostname; };
            users.katob.imports = [ homePath ] ++ resolveProfiles "home" profiles;
            backupFileExtension = "backup";
          };
        }
      ] ++ resolveProfiles "system" profiles
        ++ extraModules;
    };
in {
  inherit mkHost mkDarwin;
}
```

Note: `homePath` defaults to `../hosts/<hostname>/home.nix`. We expose it as a parameter only as an escape hatch; in normal use you don't pass it.

- [ ] **Step 2: Syntax-check the file**

Run: `nix-instantiate --parse lib/default.nix > /dev/null && echo OK`

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add lib/default.nix
git commit -m "feat(lib): add mkHost and mkDarwin factory functions"
```

---

## Task 3: Convert `mac-studio` (lowest-risk: it's a duplicate of mac-personal)

**Files:**
- Create: `hosts/mac-studio/system.nix`
- Create: `hosts/mac-studio/home.nix`
- Modify: `flake.nix` (replace mac-studio block)

- [ ] **Step 1: Create the host directory wrappers**

Create `hosts/mac-studio/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/hosts/personal/configuration.nix
  ];
}
```

Create `hosts/mac-studio/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/home/default.nix
  ];
}
```

- [ ] **Step 2: Refactor `flake.nix`**

In `flake.nix`, locate the `outputs = inputs@{ … }: let system = "x86_64-linux"; … in {` block. Add the lib import inside the `let` block, just after `pkgs = …`:

```nix
      lib = import ./lib { inherit inputs overlays; };
      inherit (lib) mkHost mkDarwin;
```

Then replace the entire `mac-studio = darwin.lib.darwinSystem { … };` block (currently lines ~182-203) with this single line:

```nix
        mac-studio = mkDarwin {
          hostname = "mac-studio";
          system = "aarch64-darwin";
        };
```

- [ ] **Step 3: Syntax-check and evaluate**

Run: `nix flake check --no-build 2>&1 | head -20`

Expected: no eval errors. (Build warnings about `useGlobalPkgs` etc. are fine; we're only checking that evaluation completes.)

- [ ] **Step 4: Verify closure is unchanged**

Run:
```bash
new=$(nix eval --raw .#darwinConfigurations.mac-studio.config.system.build.toplevel.outPath)
old=$(awk '$1=="mac-studio"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
echo "OLD: $old"
echo "NEW: $new"
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH — investigate before proceeding"
```

Expected: `MATCH`. If `MISMATCH`, the refactor changed something semantically. Diff the old vs new flake block, double-check the wrapper file imports point at the correct existing path, and don't proceed until matched.

- [ ] **Step 5: Commit**

```bash
git add hosts/mac-studio/ flake.nix
git commit -m "refactor(flake): convert mac-studio to mkDarwin factory"
```

---

## Task 4: Convert `mac-personal`

**Files:**
- Create: `hosts/mac-personal/system.nix`
- Create: `hosts/mac-personal/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/mac-personal/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/hosts/personal/configuration.nix
  ];
}
```

Create `hosts/mac-personal/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/home/default.nix
  ];
}
```

- [ ] **Step 2: Replace mac-personal block in flake.nix**

Locate the existing `mac-personal = darwin.lib.darwinSystem { … };` block and replace with:

```nix
        mac-personal = mkDarwin {
          hostname = "mac-personal";
          system = "aarch64-darwin";
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#darwinConfigurations.mac-personal.config.system.build.toplevel.outPath)
old=$(awk '$1=="mac-personal"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
echo "OLD: $old"; echo "NEW: $new"
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/mac-personal/ flake.nix
git commit -m "refactor(flake): convert mac-personal to mkDarwin factory"
```

---

## Task 5: Convert `mac-work`

**Files:**
- Create: `hosts/mac-work/system.nix`
- Create: `hosts/mac-work/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/mac-work/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/hosts/work/configuration.nix
  ];
}
```

Create `hosts/mac-work/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/home/work/default.nix
  ];
}
```

- [ ] **Step 2: Replace mac-work block in flake.nix**

```nix
        mac-work = mkDarwin {
          hostname = "mac-work";
          system = "x86_64-darwin";
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#darwinConfigurations.mac-work.config.system.build.toplevel.outPath)
old=$(awk '$1=="mac-work"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/mac-work/ flake.nix
git commit -m "refactor(flake): convert mac-work to mkDarwin factory"
```

---

## Task 6: Convert `frame13` (note: has its own per-host home directory)

**Files:**
- Create: `hosts/frame13/system.nix`
- Create: `hosts/frame13/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/frame13/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/hosts/frame13/configuration.nix
  ];
}
```

Create `hosts/frame13/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/hosts/frame13/home/default.nix
  ];
}
```

- [ ] **Step 2: Replace frame13 block in flake.nix**

```nix
        frame13 = mkHost {
          hostname = "frame13";
          system = "x86_64-linux";
          extraModules = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#nixosConfigurations.frame13.config.system.build.toplevel.outPath)
old=$(awk '$1=="frame13"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/frame13/ flake.nix
git commit -m "refactor(flake): convert frame13 to mkHost factory"
```

---

## Task 7: Convert `frame16`

**Files:**
- Create: `hosts/frame16/system.nix`
- Create: `hosts/frame16/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/frame16/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/hosts/frame16/configuration.nix
  ];
}
```

Create `hosts/frame16/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/home/default.nix
  ];
}
```

- [ ] **Step 2: Replace frame16 block in flake.nix**

```nix
        frame16 = mkHost {
          hostname = "frame16";
          system = "x86_64-linux";
          extraModules = [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#nixosConfigurations.frame16.config.system.build.toplevel.outPath)
old=$(awk '$1=="frame16"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/frame16/ flake.nix
git commit -m "refactor(flake): convert frame16 to mkHost factory"
```

---

## Task 8: Convert `main`

**Files:**
- Create: `hosts/main/system.nix`
- Create: `hosts/main/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/main/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/hosts/main/configuration.nix
  ];
}
```

Create `hosts/main/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/home/default.nix
  ];
}
```

- [ ] **Step 2: Replace main block in flake.nix**

```nix
        main = mkHost {
          hostname = "main";
          system = "x86_64-linux";
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#nixosConfigurations.main.config.system.build.toplevel.outPath)
old=$(awk '$1=="main"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/main/ flake.nix
git commit -m "refactor(flake): convert main to mkHost factory"
```

---

## Task 9: Convert `server`

**Files:**
- Create: `hosts/server/system.nix`
- Create: `hosts/server/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/server/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/hosts/server/configuration.nix
  ];
}
```

Create `hosts/server/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/home/default.nix
  ];
}
```

- [ ] **Step 2: Replace server block in flake.nix**

```nix
        server = mkHost {
          hostname = "server";
          system = "x86_64-linux";
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#nixosConfigurations.server.config.system.build.toplevel.outPath)
old=$(awk '$1=="server"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/server/ flake.nix
git commit -m "refactor(flake): convert server to mkHost factory"
```

---

## Task 10: Convert `util`

**Files:**
- Create: `hosts/util/system.nix`
- Create: `hosts/util/home.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Create wrapper files**

Create `hosts/util/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/hosts/util/configuration.nix
  ];
}
```

Create `hosts/util/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/nixos/home/default.nix
  ];
}
```

- [ ] **Step 2: Replace util block in flake.nix**

```nix
        util = mkHost {
          hostname = "util";
          system = "x86_64-linux";
        };
```

- [ ] **Step 3: Verify closure unchanged**

```bash
new=$(nix eval --raw .#nixosConfigurations.util.config.system.build.toplevel.outPath)
old=$(awk '$1=="util"{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
[ "$old" = "$new" ] && echo "MATCH" || echo "MISMATCH"
```

Expected: `MATCH`.

- [ ] **Step 4: Commit**

```bash
git add hosts/util/ flake.nix
git commit -m "refactor(flake): convert util to mkHost factory"
```

---

## Task 11: Confirm `flake.nix` is now lean

**Files:**
- Read-only: `flake.nix`

- [ ] **Step 1: Inspect flake.nix**

Run: `wc -l flake.nix && grep -c 'darwinSystem\|nixosSystem' flake.nix`

Expected: `flake.nix` is now ~80-100 lines. The count of `darwinSystem`/`nixosSystem` literal references should be **0** (all routed through the factories now).

- [ ] **Step 2: All hosts still match baseline**

```bash
echo "=== Sanity check across all hosts ==="
for host in frame13 frame16 main server util; do
  new=$(nix eval --raw .#nixosConfigurations.$host.config.system.build.toplevel.outPath 2>/dev/null)
  old=$(awk -v h="$host" '$1==h{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
  [ "$old" = "$new" ] && echo "$host  OK" || echo "$host  MISMATCH (old=$old new=$new)"
done
for host in mac-personal mac-studio mac-work; do
  new=$(nix eval --raw .#darwinConfigurations.$host.config.system.build.toplevel.outPath 2>/dev/null)
  old=$(awk -v h="$host" '$1==h{print $2}' docs/superpowers/plans/_baselines/step1-baselines.txt)
  [ "$old" = "$new" ] && echo "$host  OK" || echo "$host  MISMATCH (old=$old new=$new)"
done
```

Expected: 8 lines, all `OK`. Stop and investigate the first mismatch if any.

---

## Task 12: Add `macbook-neo` host

**Files:**
- Create: `hosts/macbook-neo/system.nix`
- Create: `hosts/macbook-neo/home.nix`
- Modify: `flake.nix`

This is **not** a refactor — it's a new host. There's no closure baseline to match. Treat the existing `mac-personal` config as the starting reference; macbook-neo can diverge later via the host file.

- [ ] **Step 1: Create wrapper files initially mirroring mac-personal**

Create `hosts/macbook-neo/system.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/hosts/personal/configuration.nix
  ];
}
```

Create `hosts/macbook-neo/home.nix`:

```nix
{ ... }: {
  imports = [
    ../../os/darwin/home/default.nix
  ];
}
```

- [ ] **Step 2: Add macbook-neo entry to flake.nix**

In `flake.nix`, inside the `darwinConfigurations = { … };` block, add:

```nix
        macbook-neo = mkDarwin {
          hostname = "macbook-neo";
          system = "aarch64-darwin";
        };
```

- [ ] **Step 3: Evaluate the new host**

Run: `nix eval --raw .#darwinConfigurations.macbook-neo.config.system.build.toplevel.outPath`

Expected: a `/nix/store/<hash>-darwin-system-…` path. No errors.

- [ ] **Step 4: Build (don't switch yet)**

Run: `nix build .#darwinConfigurations.macbook-neo.config.system.build.toplevel --no-link --print-out-paths`

Expected: a store path is printed. The build should complete in a few minutes (most derivations are shared with `mac-personal` so cache is hot).

- [ ] **Step 5: Commit**

```bash
git add hosts/macbook-neo/ flake.nix
git commit -m "feat(hosts): add macbook-neo (aarch64-darwin) using mkDarwin factory"
```

---

## Task 13: Activate `macbook-neo` on this machine

This is the moment of truth — switching this machine from `mac-personal` (or `mac-studio`) to `macbook-neo`. The closure should be near-identical, so activation is essentially a hostname change plus regeneration of a few hostname-derived files. Still a real activation; back out is `darwin-rebuild switch --flake .#mac-personal`.

- [ ] **Step 1: Confirm current active configuration before switching**

Run: `darwin-rebuild --list-generations | tail -5; scutil --get LocalHostName`

Note the current generation number and hostname. You'll roll back to this generation if anything goes wrong.

- [ ] **Step 2: Switch to macbook-neo**

Run: `darwin-rebuild switch --flake .#macbook-neo`

Expected: activation succeeds. Hostname changes (the system may prompt you to enter sudo). The first run will write a new generation; successive `nix-darwin` operations will reference `macbook-neo` instead of `mac-personal`.

- [ ] **Step 3: Verify new hostname is live**

Run: `hostname; scutil --get LocalHostName 2>/dev/null; darwin-rebuild --list-generations | tail -3`

Expected: `hostname` and `LocalHostName` reflect the new host (the factory sets `networking.hostName = "macbook-neo"`; macOS may take an extra reboot to fully sync `LocalHostName`). A new generation is appended to the list.

- [ ] **Step 4: Smoke test critical user-facing things**

- Open a new terminal — your shell prompt and aliases should work as before.
- Verify Hammerspoon hotkeys still work (Ctrl+Space → WezTerm).
- Verify Zen browser launches.
- Verify Claude Code's MCP servers are still wired (`/mcp` should list jobdrop, ECC plugin, etc.).

If anything is broken: `darwin-rebuild --switch-generation <previous>` to roll back, then investigate.

- [ ] **Step 5: Commit nothing (no code changes); record outcome**

No commit needed for the switch itself. If the smoke test passed, Step 1 is complete. If it failed and you rolled back, file an issue note in the spec's `§10 Open Decisions` for follow-up.

---

## Task 14: Final verification & cleanup

**Files:**
- Read-only: `flake.nix`, `hosts/`, `lib/default.nix`

- [ ] **Step 1: All 9 hosts evaluate**

```bash
for host in frame13 frame16 main server util; do
  echo -n "$host: "; nix eval --raw .#nixosConfigurations.$host.config.system.build.toplevel.outPath 2>&1 | tail -1
done
for host in mac-personal mac-studio mac-work macbook-neo; do
  echo -n "$host: "; nix eval --raw .#darwinConfigurations.$host.config.system.build.toplevel.outPath 2>&1 | tail -1
done
```

Expected: 9 store paths, no errors.

- [ ] **Step 2: Inspect the new directory layout**

Run: `find hosts lib -maxdepth 2 -type f | sort`

Expected: each host has a `system.nix` and `home.nix`; `lib/default.nix` exists.

- [ ] **Step 3: Confirm `flake.nix` line count**

Run: `wc -l flake.nix`

Expected: ≤120 lines (we should be ~80-100).

- [ ] **Step 4: Final commit (no-op if everything was already committed)**

```bash
git status --short
```

If clean, Step 1 is shipped. If dirty, review and commit with descriptive messages — don't bundle unrelated changes.

---

## What this leaves for Step 2

- `os/`, `common/`, `modules/` (current — only browser stuff) are still in place. They will be migrated in Steps 2-5 of the spec.
- `profiles/` doesn't exist yet — `lib/default.nix` calls `resolveProfiles` but `builtins.pathExists` returns false for every name, so it's a no-op.
- `ai.nix` is still 700 lines. Step 2 (separate plan) will split it.
- Each host file is currently ~5 lines. The richer host shape from §4.2 of the spec lands in Step 3.

When Step 1 is fully shipped, request the next plan: `2026-05-08-nix-restructure-step2-split-ai-nix.md`.
