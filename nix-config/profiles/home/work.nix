{ lib, ... }: {
  # ===================================================================
  # WORK-LAPTOP ISOLATION POLICY (mac-work)
  # ===================================================================
  # The work blueprint imports the same topic umbrellas as personal
  # hosts, and umbrellas default-enable their members — so anything NOT
  # explicitly disabled here lands on the corporate laptop.  This file
  # is the single place that says what work does NOT get.  The CI
  # tripwire in .github/workflows/nix-eval.yml enforces it.
  #
  # Sanctioned on work: claude-code (nix-managed settings/skills;
  # binary via brew), firefox from nix; Edge/Helium are corp/brew
  # managed, outside nix.

  # --- AI: claude-code + rtk ONLY --------------------------------
  modules.ai.claude-code.enable            = true;
  modules.ai.rtk.enable                    = true;   # sanctioned for work
  modules.ai.opencode.enable               = false;
  modules.ai.kimi-cli.enable               = false;
  modules.ai.mcp-servers.enable            = false;
  modules.ai.jobdrop.enable                = false;  # job scraper — NEVER on work
  modules.ai.understand-anything.enable    = false;
  modules.ai.pi-coding-agent.enable        = false;
  modules.ai.no-hallucination.enable       = false;
  modules.ai.hallucination-detector.enable = false;

  # --- Browsers: firefox only from nix ---------------------------
  modules.browsers.zen.enable = false;   # re-signed bundle — endpoint-security bait

  # --- Personal tools --------------------------------------------
  modules.shell.bookokrat.enable        = false;
  modules.shell.claude-acp.enable       = false;  # npm-fetched; Zscaler blocks npm at work
  modules.packages.personalTools.enable = false;  # nmap/newsboat/taskwarrior
}
