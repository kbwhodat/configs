# Migration shim. Real config in modules/home/personal/.
# ai.nix shim still imports modules/home/ai (Step 2).
{ ... }: {
  imports = [
    ../../modules/home/personal
    ./ai.nix
  ];
}
