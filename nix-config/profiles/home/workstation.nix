{ ... }: {
  # Step 3: declare AI-tooling intent at the profile layer.
  # Today this is moot — common/personal/ai.nix shim already enables
  # modules.ai.enable globally. After Step 4 removes the shim, this
  # profile becomes the single source of truth for AI-on hosts.
  modules.ai.enable = true;
}
