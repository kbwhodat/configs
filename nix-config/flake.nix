{
  description = "A template that shows all standard flake outputs";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  inputs.home-manager.url = "github:nix-community/home-manager/9c6f1307e1d76a2285d8001e1b8bc281bfe15dac";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
  inputs.llm-agents.url = "github:numtide/llm-agents.nix/main";

  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur.inputs.nixpkgs.follows = "nixpkgs";

  inputs.darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";

  inputs.zen-browser.url = "github:kbwhodat/zen-browser-flake";
  inputs.zen-browser.inputs.nixpkgs.follows = "nixpkgs";

  inputs.thorium-browser.url = "github:kbwhodat/thorium-browser-flake";
  inputs.thorium-browser.inputs.nixpkgs.follows = "nixpkgs";

  inputs.chawan-flake.url = "github:kbwhodat/chawan-nix-flake";

  inputs.undetected-chromedriver.url = "github:kbwhodat/undetected-chromedriver/8b0bd1e599c8367040eb5578f9c191846945f838";

  inputs.gonchill.url = "github:kbwhodat/gonchill?ref=1.1.1";
  inputs.gonwatch.url = "github:kbwhodat/gonwatch/main";

  inputs.coding-agents.url = "github:kissgyorgy/coding-agents/b393ce8f3bc7d3a780fffb77f6f133d690ef9f21";
  inputs.coding-agents.inputs.nixpkgs.follows = "unstable";

  inputs.everything-claude-code = { url = "github:affaan-m/everything-claude-code";   flake = false; };
  inputs.wshobson-agents        = { url = "github:wshobson/agents";                   flake = false; };
  inputs.mattpocock-skills      = { url = "github:mattpocock/skills";                 flake = false; };
  inputs.superpowers            = { url = "github:obra/superpowers";                  flake = false; };
  inputs.understand-anything    = { url = "github:Lum1104/Understand-Anything";       flake = false; };

  outputs = inputs@{ self, unstable, llm-agents, mcp-servers-nix, nixpkgs, nixos-hardware, home-manager, darwin, undetected-chromedriver, nur, sops-nix, gonchill, gonwatch, zen-browser, ... }:

    let
      system = "x86_64-linux";

      overlays = [
        nur.overlays.default
        # gonchill.overlay
        gonwatch.overlay
        # firefox-darwin.overlay
        undetected-chromedriver.overlay
        (import ./pkgs/overlay.nix)
        # libfyaml 0.9.6 on darwin: AX_PTHREAD probe leaks "none required"
        # into PTHREAD_LIBS, which the .pc.in template substitutes into the
        # Libs: line. Every pkg-config consumer (appstream → zathura plugins)
        # then fails to link with `clang: error: no such file or directory:
        # 'none' / 'required'`. Upstream fix: pantoniou/libfyaml#275 (post-0.9.6).
        # Equivalent of closed PR NixOS/nixpkgs#519320.
        (final: prev: {
          libfyaml = prev.libfyaml.overrideAttrs (old: {
            postConfigure = (old.postConfigure or "") + prev.lib.optionalString prev.stdenv.hostPlatform.isDarwin ''
              substituteInPlace libfyaml.pc --replace-fail "none required" ""
            '';
          });
        })
      ];

      pkgs = import nixpkgs {
        inherit system;
        overlays = overlays;
        config = {
          allowUnfree = true;
        };
      };

      lib = import ./lib { inherit inputs overlays; };
      inherit (lib) mkHost mkDarwin;
    in {
      nixosConfigurations = {
        util = mkHost {
          hostname = "util";
          system = "x86_64-linux";
          profiles = [ "base" "server" ];
        };

        frame13 = mkHost {
          hostname = "frame13";
          system = "x86_64-linux";
          profiles = [ "base" "desktop" "laptop" "workstation" ];
          extraModules = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
        };

        server = mkHost {
          hostname = "server";
          system = "x86_64-linux";
          profiles = [ "base" "server" ];
        };

        main = mkHost {
          hostname = "main";
          system = "x86_64-linux";
          profiles = [ "base" "desktop" "workstation" "gaming" ];
        };
      };

      darwinConfigurations = {

        mac-work = mkDarwin {
          hostname = "mac-work";
          system = "x86_64-darwin";
          profiles = [ "base" "desktop" "workstation" "work" ];
        };

        mac-studio = mkDarwin {
          hostname = "mac-studio";
          system = "aarch64-darwin";
          profiles = [ "base" "desktop" "workstation" ];
        };

        mac-personal = mkDarwin {
          hostname = "mac-personal";
          system = "aarch64-darwin";
          profiles = [ "base" "desktop" "workstation" ];
        };

        macbook-neo = mkDarwin {
          hostname = "macbook-neo";
          system = "aarch64-darwin";
          profiles = [ "base" "desktop" "workstation" ];
        };
      };
    };
}
