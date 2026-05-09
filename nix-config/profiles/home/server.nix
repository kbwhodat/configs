{ lib, ... }: {
  # Server hosts are headless; force AI tooling off so the umbrella
  # cannot accidentally land on them via the shim.
  modules.ai.enable = lib.mkForce false;
}
