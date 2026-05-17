# nix-config — Project Conventions for Agents

Read this first. It documents the structure and patterns of this Nix flake so changes stay consistent. **When in doubt, copy the nearest sibling file — every directory has 3-10 examples of its own pattern.**

## Layout

```
flake.nix              # inputs + nixosConfigurations + darwinConfigurations
flake.lock             # do not hand-edit; use `nix flake lock --update-input <name>`
lib/default.nix        # mkHost / mkDarwin factories — single source of truth for host wiring
hosts/<name>/          # thin per-host wrappers (system.nix, home.nix) — usually one-liners
hosts/_shared/         # shared host blueprints (darwin-personal-home.nix, nixos-home.nix, ...)
modules/home/<topic>/  # home-manager modules, one file per program
modules/system/<topic>/ # system-level modules (nvidia, ssh, ...)
profiles/system/       # composable system profiles (base, desktop, server, gaming, ...)
profiles/home/         # composable home profiles (mirror system list)
pkgs/by-name/          # custom packages (nixpkgs `by-name` layout)
pkgs/overlay.nix       # overlay that exposes pkgs/by-name/* as pkgs.<name>
```

## Host wiring

`flake.nix` calls `mkHost` (NixOS) or `mkDarwin` (macOS) per host. Both factories live in `lib/default.nix`. A host entry looks like:

```nix
macbook-neo = mkDarwin {
  hostname = "macbook-neo";
  system = "aarch64-darwin";
  profiles = [ "base" "desktop" "workstation" ];
};
```

`profiles` resolves to `profiles/system/<name>.nix` and `profiles/home/<name>.nix` (silently skipped if a layer doesn't exist). Per-host files live at `hosts/<name>/{system,home}.nix` and almost always just `imports = [ ../_shared/<blueprint>.nix ]`. Don't add config in the per-host file unless it's truly host-specific — push it to a shared blueprint or a module.

## Per-program module pattern (CRITICAL)

**Every program/agent/tool gets its own file** under `modules/<scope>/<topic>/<name>.nix` with an `enable` flag. The topic's `default.nix` is an umbrella that imports the per-program files and toggles them on with `mkDefault true`. Do **not** stuff package installs into the umbrella's `default.nix` — break the rule and you fight the whole repo.
## Host platform map

| Host         | System            | Notes                                                                     |
| ------------ | ----------------- | ------------------------------------------------------------------------- |
### Template (per-program file)

```nix
{ config, lib, pkgs, ... }:
let cfg = config.modules.<topic>.<name>; in {
  options.modules.<topic>.<name>.enable = lib.mkEnableOption "<one-line description>";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.<name> ];
    # ...any other home-manager config gated by cfg.enable
  };
}
```

### Template (umbrella `default.nix`)

```nix
{ config, lib, ... }:
let cfg = config.modules.<topic>; in {
  imports = [
    ./foo.nix
    ./bar.nix
  ];

  options.modules.<topic>.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "<topic> umbrella";
  };

  config = lib.mkIf cfg.enable {
    modules.<topic>.foo.enable = lib.mkDefault true;
    modules.<topic>.bar.enable = lib.mkDefault true;
  };
}
```

Canonical examples to copy from: `modules/home/ai/jobdrop.nix` (uv-tool install), `modules/home/ai/pi-coding-agent.nix` (flake-sourced package, platform-gated), `modules/home/ai/hermes.nix` (activation script).

## Adding a flake input

1. Declare in `flake.nix`:
   ```nix
   inputs.<name>.url = "github:owner/repo";
   inputs.<name>.inputs.nixpkgs.follows = "unstable";  # or "nixpkgs" — match upstream's pin
   ```
2. Lock: `nix flake lock --update-input <name>`.
3. Consume in a module — for packages, prefer pulling from the input's `packages.<system>` rather than applying its overlay (overlays clobber attrs your other modules expect). Gate with a platform check:
   ```nix
   sys = pkgs.stdenv.hostPlatform.system;
   src = inputs.<name>.packages.${sys} or { };
   in lib.mkIf (cfg.enable && src ? <pkg>) {
     home.packages = [ src.<pkg> ];
   }
   ```
4. If the module needs `inputs`, add it to the function args (`{ config, lib, pkgs, inputs, ... }:`). It's threaded through by `lib/default.nix` via `extraSpecialArgs`.

## Custom packages

Drop a `package.nix` under `pkgs/by-name/<name>/` (nixpkgs `by-name` layout). `pkgs/overlay.nix` picks it up automatically and exposes it as `pkgs.<name>`.





| util         | x86_64-linux      | server profile                                                            |
| frame13      | x86_64-linux      | desktop+laptop+workstation, framework-13 hw                               |
| server       | x86_64-linux      | server profile                                                            |
| main         | x86_64-linux      | desktop+workstation+gaming                                                |
| mac-work     | **x86_64-darwin** | Intel mac — many flakes don't build for this; gate flake-sourced packages |
| mac-studio   | aarch64-darwin    |                                                                           |
| mac-personal | aarch64-darwin    |                                                                           |
| macbook-neo  | aarch64-darwin    | personal blueprint                                                        |

## Verification

- Eval (fast structural check, no build): `nix eval .#darwinConfigurations.<host>.config.system.build.toplevel --apply 'x: x.outPath'`
- Inspect a single attr: `nix eval .#darwinConfigurations.<host>.config.home-manager.users.katob.home.packages --apply '...'`
- Build & switch: `darwin-rebuild switch --flake .#<host>` (macOS) / `nixos-rebuild switch --flake .#<host>` (NixOS).
- Untracked new files break eval — `git add --intent-to-add <file>` so flake reads them.

## Notes that bite

- `home.sessionPath = [ "$HOME/.local/bin" ]` lives in `modules/home/ai/default.nix` for uv-tool installs (jobdrop, hermes).
- Modules that need `unstable` import it explicitly: `import inputs.unstable { system = pkgs.stdenv.hostPlatform.system; ... }`. See `modules/home/ai/rtk.nix`.
- `extraSpecialArgs = { inherit inputs; }` (and `hostname` on darwin) is set in `lib/default.nix` — that's how modules get `inputs`.
- Don't `nixpkgs.overlays = [...]` in a module; overlays go through `lib/default.nix` and the `overlays` list in `flake.nix`.
