{
  description = "A template that shows all standard flake outputs";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  # Using Lix -- which essentially a nix upgrade with extra features and optimizations
  # inputs.lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
  # inputs.lix-module.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nil.url = "github:oxalica/nil";

  #inputs.home-manager.url = "github:nix-community/home-manager/release-24.11";
  inputs.home-manager.url = "github:nix-community/home-manager/master";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.nixpkgs.url = "github:matteo-pacini/nixpkgs/gtk3-clang-fixes-2";

  inputs.mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
  inputs.llm-agents.url = "github:numtide/llm-agents.nix/main";
  inputs.ocv.url = "github:leohenon/opencode-vim/v1.14.25-ocv.3.28";

  inputs.nur.url = "github:nix-community/NUR";
  inputs.nur.inputs.nixpkgs.follows = "nixpkgs";

  # inputs.darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
  inputs.darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";

  # inputs.firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin/main";
  inputs.zen-browser.url = "github:kbwhodat/zen-browser-flake";
  inputs.zen-browser.inputs.nixpkgs.follows = "nixpkgs";

  inputs.thorium-browser.url = "github:kbwhodat/thorium-browser-flake";
  inputs.thorium-browser.inputs.nixpkgs.follows = "nixpkgs";

  inputs.chawan-flake.url = "github:kbwhodat/chawan-nix-flake";

  inputs.undetected-chromedriver.url = "github:kbwhodat/undetected-chromedriver/8b0bd1e599c8367040eb5578f9c191846945f838";

  inputs.gonchill.url = "github:kbwhodat/gonchill?ref=1.1.1";
  inputs.gonwatch.url = "github:kbwhodat/gonwatch/main";
  # inputs.gonchill.url = "github:kbwhodat/gonchill/2607f4315c455d6303afb8b20d9ee9cbe694686e";

  inputs.matcha.url = "github:floatpane/matcha";
  # Follow `unstable` (not stable nixpkgs): matcha's go.mod requires
  # Go ≥ 1.26.3; matcha's pinned nixpkgs has 1.26.2; our nixos-25.11
  # is older still; only nixos-unstable has a recent enough go_1_26.
  inputs.matcha.inputs.nixpkgs.follows = "unstable";

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
