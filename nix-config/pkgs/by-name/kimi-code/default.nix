{ lib
, stdenvNoCC
, fetchurl
, nodejs
, makeWrapper
}:

# `kimi-code' — MoonshotAI's terminal coding agent.  We want it for one
# reason: `kimi acp' is an Agent Client Protocol server over stdio,
# which is exactly what emacs `agent-shell' drives (see the upstream
# `agent-shell-kimi.el', whose `agent-shell-kimi-acp-command' defaults
# to `("kimi" "acp")').  Unlike Claude Code it speaks ACP natively, so
# there's no bridge package to build — cf. pkgs/by-name/claude-agent-acp.
#
# Not in nixpkgs.  Homebrew has it, but that puts the binary outside
# nix's view, and the older `kimi-cli' formula/PyPI package is
# deprecated upstream (brew disables it 2027-01-17).  So fetch the
# published npm tarball directly:
#   - it ships a prebuilt, fully-bundled `dist/main.mjs' with ZERO
#     required npm deps, so there's no lockfile/`npmDepsHash' dance
#     and no registry access at build time beyond this one fetchurl
#   - npm tarballs are immutable and content-addressed => reproducible,
#     and cacheable like any other fixed-output derivation
#   - `scripts/postinstall.mjs' is skipped: all it does is rename a
#     legacy uv/pipx-installed `kimi' shim out of the way on GLOBAL npm
#     installs. Irrelevant to a nix-store install.
#
# `optionalDependencies' (node-pty, @mariozechner/clipboard) are native
# modules and deliberately left unbuilt — the CLI starts and `kimi acp'
# serves over stdio without them. The tarball does carry darwin
# prebuilds under `native/'; there are none for linux.

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kimi-code";
  version = "0.30.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@moonshot-ai/kimi-code/-/kimi-code-${finalAttrs.version}.tgz";
    # npm's `dist.integrity' IS an SRI hash — on a version bump, paste it
    # verbatim from:
    #   curl -s https://registry.npmjs.org/@moonshot-ai/kimi-code/<ver> | jq -r .dist.integrity
    hash = "sha512-YhUXhduLxfdEFLtetQpkDIRYs290MlF7QuoH2XQJb6g6pEtYkr1jzam1kUUAqm58kQfetxw781u4qude3k2qPg==";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Prebuilt bundle — nothing to compile.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kimi-code
    cp -R . $out/lib/kimi-code/

    # `dist/main.mjs' is ESM with a node shebang; wrap rather than
    # patchShebangs so the interpreter is pinned to this nodejs.
    makeWrapper ${lib.getExe nodejs} $out/bin/kimi \
      --add-flags $out/lib/kimi-code/dist/main.mjs

    runHook postInstall
  '';

  meta = {
    description = "MoonshotAI Kimi Code CLI — terminal coding agent with an ACP server mode (`kimi acp')";
    homepage = "https://moonshotai.github.io/kimi-code/";
    license = lib.licenses.mit;
    mainProgram = "kimi";
    platforms = lib.platforms.unix;
  };
})
