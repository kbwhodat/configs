# Nix Config Restructure — Design Spec

**Date:** 2026-05-08
**Status:** Draft, pending user review
**Owner:** katob
**Repo:** `~/.config/nix-config`

---

## 1. Context

The repo currently spans 8 hosts across NixOS and Darwin. Over time it has grown several discoverability problems:

- **`common/personal/ai.nix`** is ~700 lines doing 6+ unrelated jobs (MCP servers, Claude Code, opencode, RTK, ECC plugin patching, jobdrop install).
- **Packages are scattered** across `common/personal/personal.nix`, `common/work/packages.nix`, `os/nixos/home/default.nix` (inline list), and various per-host `configuration.nix` files. There's no single source of truth for "what does this host install?".
- **`common/`** is a kitchen sink (18 subdirs) with overlapping topics (`editors/`, `neovim/`, `lsp/`).
- **Naming collisions**: `personal/personal.nix` next to `personal/default.nix`; `modules/` only contains browser stuff while real "modules" live under `common/`.
- **Per-host duplication**: each `nixosSystem` and `darwinSystem` block in `flake.nix` repeats ~15 lines of boilerplate. `mac-studio` and `mac-personal` import the same configuration — likely an unintended duplicate.
- **No mental model**: there is no consistent way to answer "what does this host have on it?" without reading multiple files.

Research on what the wider Nix community converges on (May 2026) shows three camps: plain flakes with a hand-rolled factory, flake-parts with the dendritic pattern, and Snowfall Lib (now in maintenance mode by its creator's admission). For a config of this size and trajectory, **Camp A — plain flakes + factory + profiles + enable-flag modules** is the right fit: minimal new abstraction, no framework lock-in, easy migration path to flake-parts later if scale demands it.

## 2. Goals

1. Make every host answerable from a single ~10-line file: *what role does this machine play, and what features are on/off?*
2. Reduce `flake.nix` from ~225 lines of duplicated `nixosSystem`/`darwinSystem` blocks to ~80 lines of declarative host definitions.
3. Split `ai.nix` (and any file >200 lines) into focused single-purpose units.
4. Establish one canonical place for system packages, home packages, MCP servers, and feature toggles.
5. Add `macbook-neo` as a first-class host using the new layout.
6. Keep all 9 hosts buildable at every step of the migration. No big-bang.

## 3. Non-Goals

- **Not** moving to flake-parts, snowfall, dendritic, haumea, or any framework. Stay in plain Nix.
- **Not** redesigning home-manager integration — keep it as a NixOS/Darwin module (current pattern). Standalone home-manager is a future option, not part of this work.
- **Not** rewriting individual program configs (zsh, neovim, etc.) — only relocating them.
- **Not** changing `pkgs/by-name/` — it's already correct.
- **Not** changing secret management — sops-nix stays as is.

## 4. Target Architecture

### 4.1 Top-level layout

```
nix-config/
├── flake.nix                    # ~80 lines: inputs + mkHost/mkDarwin calls
├── flake.lock
├── lib/
│   └── default.nix              # mkHost, mkDarwin factories + helpers
├── hosts/
│   ├── mac-personal/
│   ├── mac-studio/              # decision: collapse or keep (see §10)
│   ├── mac-work/
│   ├── macbook-neo/             # NEW
│   ├── frame13/
│   ├── frame16/
│   ├── main/
│   ├── server/
│   └── util/
├── profiles/
│   ├── system/                  # imported at NixOS / nix-darwin layer
│   │   ├── base.nix
│   │   ├── desktop.nix          # X/Wayland baseline (Linux), GUI baseline (Darwin)
│   │   ├── laptop.nix           # power management, fingerprint, battery
│   │   ├── server.nix           # headless, no GUI
│   │   ├── work.nix             # work-only system overrides (e.g. VPN)
│   │   └── gaming.nix
│   └── home/                    # imported at home-manager layer
│       ├── base.nix             # shell + base CLI tooling every host gets
│       ├── desktop.nix          # browsers, fonts, GUI apps
│       ├── workstation.nix      # editors, AI tools, dev languages
│       ├── server.nix           # minimal home setup for headless
│       ├── work.nix             # work-only home overrides (e.g. corporate IDE)
│       └── gaming.nix
├── modules/
│   ├── system/                  # NixOS + Darwin modules
│   │   ├── default.nix          # auto-imports everything
│   │   ├── nix-settings/
│   │   ├── networking/
│   │   ├── nvidia/              # gated by config.modules.hardware.nvidia.enable
│   │   ├── macos/               # darwin-only stuff (aerospace, hammerspoon)
│   │   └── …
│   └── home/
│       ├── default.nix
│       ├── shell/
│       ├── editors/
│       ├── browsers/
│       ├── ai/                  # ai.nix split lives here
│       │   ├── default.nix
│       │   ├── claude-code.nix
│       │   ├── opencode.nix
│       │   ├── mcp-servers.nix
│       │   ├── jobdrop.nix
│       │   └── rtk.nix
│       ├── neovim/
│       └── …
├── pkgs/
│   ├── by-name/                 # unchanged
│   └── overlay.nix              # unchanged
├── secrets/                     # unchanged
└── templates/                   # unchanged
```

**Removed after migration completes:** `os/`, current `common/`, current `modules/` (browsers-only), `common/nixos-config/`. Their contents move into `hosts/`, `profiles/`, and the new `modules/`.

### 4.2 Host file shape

Every host is a tiny manifest. Example for `macbook-neo`:

```nix
# hosts/macbook-neo/default.nix
{ inputs, hostname, ... }: {
  imports = [
    ./hardware.nix          # Apple Silicon hints, if any
  ];

  modules.ai.claude-code.enable     = true;
  modules.ai.opencode.enable        = true;
  modules.browsers.zen.enable       = true;
  modules.editors.neovim.enable     = true;

  # macbook-neo-specific overrides go here, nothing else
}
```

Profiles attached to this host (in `flake.nix`) handle the rest.

### 4.3 Profile shape

Profiles only toggle enable-flags on the modules that live at the same layer (system or home). They do not contain raw config. Profiles are split into `profiles/system/` and `profiles/home/` because system-level and home-level option namespaces are evaluated separately — a home-only option referenced from a system profile would error.

Example home-layer profile (toggles home-manager modules):

```nix
# profiles/home/workstation.nix
{ ... }: {
  modules.shell.zsh.enable          = true;
  modules.shell.starship.enable     = true;
  modules.editors.neovim.enable     = true;
  modules.editors.emacs.enable      = true;
  modules.ai.claude-code.enable     = true;
  modules.ai.opencode.enable        = true;
  modules.dev.languages             = [ "rust" "typescript" "go" "python" ];
}
```

Example system-layer profile (toggles NixOS / nix-darwin modules):

```nix
# profiles/system/laptop.nix
{ ... }: {
  modules.hardware.power-management.enable = true;
  modules.hardware.fingerprint.enable      = true;
}
```

Convention: a profile name (e.g. `workstation`) may exist at one or both layers. Hosts request the *name* once — the factory wires the system version to the system layer and the home version to the home layer (see §5). If only one side has a `<name>.nix`, the other side is silently skipped.

### 4.4 Module shape (enable-flag pattern)

Every module under `modules/` declares one enable option and conditionally applies config:

```nix
# modules/home/ai/claude-code.nix
{ config, lib, pkgs, inputs, ... }:
let cfg = config.modules.ai.claude-code; in {
  options.modules.ai.claude-code = {
    enable = lib.mkEnableOption "Claude Code with ECC + superpowers plugins";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = inputs.unstable.claude-code;
      marketplaces  = { … };
      plugins       = [ … ];
      mcpServers    = { … };
    };
  };
}
```

Rules:
- One enable flag per leaf module.
- All work goes inside `lib.mkIf cfg.enable`.
- Modules are imported unconditionally (the import tree is static; the work is gated).
- This is the "import all + enable" pattern (kobimedrish.com).

### 4.5 Per-host divergence patterns

When two hosts share most of their setup but disagree on a few packages or features, there are three levers, ordered from coarse to fine. Pick the lowest-effort one that fits.

#### Lever 1 — Different profile lists (coarse, cleanest)

Use when one host has a big bundle the other doesn't.

```nix
# flake.nix
mac-studio  = mkDarwin { profiles = [ "base" "desktop" "workstation" "media" "gaming" ]; };
macbook-neo = mkDarwin { profiles = [ "base" "desktop" "workstation" ]; };
```

Studio gets `media` + `gaming` profiles (whole bundles of extra packages); neo doesn't. The diff is one line in `flake.nix` and the profiles themselves explain the bundle contents.

#### Lever 2 — Host-file overrides (fine, best for one-off exceptions)

Use when a host needs to drop or add a single feature relative to its profiles.

```nix
# hosts/macbook-neo/default.nix
{ lib, ... }: {
  # neo inherits workstation, but skip emacs and the heavy AI stack
  modules.editors.emacs.enable      = lib.mkForce false;
  modules.ai.opencode.enable        = lib.mkForce false;

  # neo-only experimental thing not in any profile
  modules.experimental.foo.enable   = true;
}
```

`lib.mkForce false` overrides the profile's `enable = true`. The host file is the final word.

#### Lever 3 — Split the module into sub-flags (finest)

Use when a single module bundles multiple things and a host wants only some of them. Promote the bundle into individual enable flags so hosts/profiles can pick.

```nix
# modules/home/dev/default.nix
options.modules.dev = {
  rust.enable    = lib.mkEnableOption "Rust toolchain";
  haskell.enable = lib.mkEnableOption "Haskell toolchain";
  go.enable      = lib.mkEnableOption "Go toolchain";
};
config = lib.mkMerge [
  (lib.mkIf cfg.rust.enable    { home.packages = [ pkgs.rustup ]; })
  (lib.mkIf cfg.haskell.enable { home.packages = [ pkgs.ghc ];    })
  (lib.mkIf cfg.go.enable      { home.packages = [ pkgs.go ];     })
];
```

Then a host or profile can selectively flip `modules.dev.rust.enable = true`.

#### Decision matrix

| Situation | Use |
|-----------|-----|
| Two hosts share most stuff, one needs a whole extra bundle (e.g. gaming, media, work) | **Lever 1** — different profile list |
| One host needs to drop or add a single feature relative to its profiles | **Lever 2** — host-file override with `lib.mkForce` |
| A module is currently "all or nothing" but you want partial inclusion | **Lever 3** — split the module into sub-flags |

#### Anti-pattern

Avoid `lib.mkIf (config.networking.hostName == "neo") { … }` inside shared modules. It hides per-host behavior in places nobody looks. If a module needs to know which host it's on, the answer is almost always "the module shouldn't know — the host or its profile should set the flag."

## 5. Factory Functions

```nix
# lib/default.nix
{ inputs, overlays }:
let
  # Resolve a profile name into the file that exists at the given layer,
  # or null if it doesn't exist there. (System profiles live in
  # profiles/system/, home profiles in profiles/home/.)
  profilePath = layer: name:
    let p = ../profiles + "/${layer}/${name}.nix";
    in if builtins.pathExists p then p else null;

  resolveProfiles = layer: profiles:
    builtins.filter (p: p != null) (map (profilePath layer) profiles);

  mkHost = { hostname, system, profiles ? [], extraModules ? [] }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        ../hosts/${hostname}
        ../modules/system
        inputs.home-manager.nixosModules.home-manager
        {
          networking.hostName = hostname;
          nixpkgs.overlays = overlays;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostname; };
            users.katob.imports =
              [ ../modules/home ]
              ++ resolveProfiles "home" profiles;
            backupFileExtension = "backup";
          };
        }
      ] ++ resolveProfiles "system" profiles
        ++ extraModules;
    };

  mkDarwin = { hostname, system, profiles ? [], extraModules ? [] }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        ../hosts/${hostname}
        ../modules/system
        inputs.home-manager.darwinModules.home-manager
        {
          networking.hostName = hostname;
          nixpkgs.overlays = overlays;
          users.users.katob = { name = "katob"; home = "/Users/katob"; };
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs hostname; };
            users.katob.imports =
              [ ../modules/home ]
              ++ resolveProfiles "home" profiles;
            backupFileExtension = "backup";
          };
        }
      ] ++ resolveProfiles "system" profiles
        ++ extraModules;
    };
in { inherit mkHost mkDarwin; }
```

Behavior:
- A host names a profile once (e.g. `"workstation"`).
- The factory looks for `profiles/system/workstation.nix` and adds it to the system layer if it exists.
- It also looks for `profiles/home/workstation.nix` and adds it to the home-manager layer if it exists.
- Neither side is required. A purely-home profile (e.g. AI tooling) lives only at `profiles/home/`. A purely-system profile (e.g. fingerprint reader) lives only at `profiles/system/`.

## 6. New `flake.nix` Shape

```nix
{
  description = "Multi-host Nix config";

  inputs = { … };  # unchanged

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, … }:
    let
      overlays = [
        inputs.nur.overlays.default
        inputs.gonwatch.overlay
        inputs.undetected-chromedriver.overlay
        (import ./pkgs/overlay.nix)
      ];

      lib = import ./lib { inherit inputs overlays; };
      inherit (lib) mkHost mkDarwin;
    in {
      nixosConfigurations = {
        frame13 = mkHost {
          hostname = "frame13"; system = "x86_64-linux";
          profiles = [ "base" "desktop" "laptop" "workstation" ];
          extraModules = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
        };
        frame16 = mkHost {
          hostname = "frame16"; system = "x86_64-linux";
          profiles = [ "base" "desktop" "laptop" "workstation" "gaming" ];
          extraModules = [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];
        };
        main   = mkHost { hostname = "main";   system = "x86_64-linux"; profiles = [ "base" "desktop" "workstation" "gaming" ]; };
        server = mkHost { hostname = "server"; system = "x86_64-linux"; profiles = [ "base" "server" ]; };
        util   = mkHost { hostname = "util";   system = "x86_64-linux"; profiles = [ "base" "server" ]; };
      };

      darwinConfigurations = {
        mac-personal = mkDarwin { hostname = "mac-personal"; system = "aarch64-darwin"; profiles = [ "base" "desktop" "workstation" ]; };
        mac-studio   = mkDarwin { hostname = "mac-studio";   system = "aarch64-darwin"; profiles = [ "base" "desktop" "workstation" ]; };
        mac-work     = mkDarwin { hostname = "mac-work";     system = "x86_64-darwin";  profiles = [ "base" "desktop" "workstation" "work" ]; };
        macbook-neo  = mkDarwin { hostname = "macbook-neo";  system = "aarch64-darwin"; profiles = [ "base" "desktop" "workstation" ]; };
      };
    };
}
```

Compared to today's ~225 lines of duplicated `darwinSystem`/`nixosSystem` blocks, this is ~30 lines of host definitions.

## 7. Host Inventory

| Host         | Platform        | Profiles                                  | Notes                                |
|--------------|-----------------|-------------------------------------------|--------------------------------------|
| frame13      | x86_64-linux    | base, desktop, laptop, workstation        | Framework 13 AMD                     |
| frame16      | x86_64-linux    | base, desktop, laptop, workstation, gaming| Framework 16 AMD                     |
| main         | x86_64-linux    | base, desktop, workstation, gaming        | Desktop                              |
| server       | x86_64-linux    | base, server                              | Headless                             |
| util         | x86_64-linux    | base, server                              | Utility / installer                  |
| mac-personal | aarch64-darwin  | base, desktop, workstation                | Currently shares config with mac-studio |
| mac-studio   | aarch64-darwin  | base, desktop, workstation                | See §10.1 for resolution             |
| mac-work     | x86_64-darwin   | base, desktop, workstation, work          | Intel Mac, work laptop               |
| **macbook-neo** | **aarch64-darwin** | **base, desktop, workstation**       | **NEW — current machine, Apple Silicon** |

## 8. `ai.nix` Breakdown

The current `common/personal/ai.nix` (~700 lines) splits as follows. Each new file gets its own enable flag.

| New file | Approx size | Contains |
|----------|-------------|----------|
| `modules/home/ai/default.nix` | ~30 lines | Imports + `modules.ai.enable` umbrella |
| `modules/home/ai/claude-code.nix` | ~120 lines | `programs.claude-code` (marketplaces, plugins, mcpServers, settings, hooks) |
| `modules/home/ai/opencode.nix` | ~150 lines | `programs.opencode` + `patchEccPlugin` activation hook |
| `modules/home/ai/mcp-servers.nix` | ~80 lines | Shared MCP server packages list |
| `modules/home/ai/jobdrop.nix` | ~30 lines | `installJobdrop` activation hook |
| `modules/home/ai/rtk.nix` | ~30 lines | `installRtk` + `installRtkClaudeHook` |

Other concerns currently in `ai.nix` move out:
- The `ocvBinary` derivation moves to `pkgs/by-name/ocv/default.nix`.
- The `unstable` import moves to `lib/default.nix` as a shared helper.

## 9. Migration Plan (Incremental, 5 Steps)

Each step ends with all 9 hosts buildable. No step requires the next.

### Step 1: Introduce `lib/default.nix` and refactor `flake.nix`
1. Create `lib/default.nix` with `mkHost` and `mkDarwin`.
2. Convert `mac-studio` first (it's a duplicate, lowest risk).
3. Verify `darwin-rebuild build --flake .#mac-studio` succeeds.
4. Convert remaining 8 hosts one at a time, verifying each.
5. Add `macbook-neo` as a host file and entry. Build it.

**Done when:** `flake.nix` is ~80 lines, all 9 hosts build.

### Step 2: Split `ai.nix` into `modules/home/ai/*`
1. Create `modules/home/ai/` with the 6 files from §8.
2. Make each file gate its config behind a fresh enable flag.
3. Replace the old `ai.nix` content with a stub that imports the new files and sets every flag to `true` (preserves current behavior).
4. Rebuild every host. Each must produce a byte-identical home-manager generation as before (or at minimum: same activation results).

**Done when:** `common/personal/ai.nix` is gone, replaced by `modules/home/ai/`.

### Step 3: Create `profiles/` and convert one host
1. Create `profiles/system/` and `profiles/home/`. Populate per §4.1: `base`, `desktop`, `laptop`, `workstation`, `server`, `work`, `gaming` (only at the layer where each makes sense).
2. Update `lib/default.nix` to use `resolveProfiles` (per §5).
3. Convert `frame13` to use profiles. The host file shrinks to ~10 lines.
4. Verify `nixos-rebuild build --flake .#frame13` produces the same closure.
5. Convert remaining 8 hosts one at a time.

**Done when:** every host file is ≤20 lines.

### Step 4: Move `common/` contents into `modules/{system,home}/<feature>/`
Migrate one topic per PR/commit:
- `common/browsers/` → `modules/home/browsers/`
- `common/editors/` → `modules/home/editors/`
- `common/shell/` → `modules/home/shell/`
- `common/macos/` → `modules/system/macos/`
- `common/linux/i3/` → `modules/system/i3/`
- … (repeat for the other ~15 subdirs)

Each topic becomes a leaf module with its own enable flag. Old paths are left as shims (`{ imports = [ ../../modules/home/browsers ]; }`) until step 5.

**Done when:** every topic in `common/` has been moved and gated.

### Step 5: Delete dead trees
1. Delete `os/`, the now-empty `common/`, the original `modules/`, `common/nixos-config/`.
2. Final `nixos-rebuild build --flake .#<host>` on every host.
3. Commit the cleanup.

**Done when:** the directory tree matches §4.1 exactly.

## 10. Open Decisions

### 10.1 mac-studio vs mac-personal

Both currently import `os/darwin/hosts/personal/configuration.nix`. Three options:
- (a) **Collapse** — drop `mac-studio` entry and rename `mac-personal` only (most likely intent based on history).
- (b) **Differentiate** — give them distinct hardware quirks once we know what each machine is.
- (c) **Keep both, identical** — fine for now; aliases cost nothing.

**Default decision:** (c) keep both during migration, revisit after step 5.

### 10.2 Profile naming

`base` / `desktop` / `laptop` / `workstation` / `server` / `work` / `gaming` — confirm these names before step 3. Alternative: `core` instead of `base`, `dev` instead of `workstation`, `headless` instead of `server`.

**Default decision:** stick with the names listed above unless objected.

### 10.3 home-manager standalone

Not in scope for this restructure. Revisit when/if there's a non-NixOS, non-Darwin target (e.g. Ubuntu work laptop).

## 11. Risks

| Risk | Mitigation |
|------|------------|
| One host silently breaks during migration | After every step, run `darwin-rebuild build --flake .#<host>` for every host. Don't move on if any fails. |
| A home-only profile is accidentally imported at the system layer (or vice versa), causing "option does not exist" | The `resolveProfiles` helper in §5 looks up `profiles/<layer>/<name>.nix` and silently skips when missing. Profile authors only need to ensure each profile file references options at its layer. |
| `ai.nix` split changes activation behavior | Step 2 keeps every flag `true` to preserve current behavior. Compare home-manager generation listings before/after. |
| Loss of git history on moved files | Use `git mv` (not delete-and-create) where possible. |
| `macbook-neo` first build pulls a different ECC/superpowers plugin commit due to `rev = "main"` | Pin both to commit hashes during migration. (Already a known footgun — see fix from earlier session.) |

## 12. Success Criteria

- [ ] `flake.nix` is ≤100 lines.
- [ ] No file in the repo exceeds 250 lines.
- [ ] Every host file is ≤20 lines (excluding hardware-configuration.nix).
- [ ] Running `nix eval .#darwinConfigurations.<host>.config.modules` returns a complete picture of every feature toggled on/off.
- [ ] `macbook-neo` builds and is the active config on this machine.
- [ ] Diffing two host configs (`diff hosts/mac-personal/default.nix hosts/macbook-neo/default.nix`) is meaningful and short.
- [ ] All 9 hosts build cleanly.
- [ ] `os/`, old `common/`, old `modules/` directories are gone.

## 13. Out of Scope (Explicit)

- Migrating to flake-parts / dendritic — possible follow-up project, not part of this work.
- Replacing sops-nix.
- Refactoring individual program configs (zsh, neovim, etc.).
- Multi-user support (configs assume `katob`).
- CI/CD for the flake.
