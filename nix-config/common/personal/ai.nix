# Compatibility shim during the Step 2 migration:
# the real config lives under modules/home/ai/. Step 4+ will retire this
# file once common/personal/default.nix's importers are rewired.
{ ... }: {
  imports = [
    ../../modules/home/ai
  ];

  modules.ai.enable = true;
}
