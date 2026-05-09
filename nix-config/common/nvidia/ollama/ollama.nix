# Migration shim. Real config in modules/system/nvidia/ollama/ollama.nix.
{ ... }: { imports = [ ../../../modules/system/nvidia/ollama/ollama.nix ]; }
