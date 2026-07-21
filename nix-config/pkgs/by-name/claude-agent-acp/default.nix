{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs
, runCommand
}:

# `claude-agent-acp` — the ACP (Agent Client Protocol) bridge that lets
# emacs's `agent-shell` talk to Claude Code.  The npm package alone
# would normally be installed via `npm install -g
# @agentclientprotocol/claude-agent-acp', but doing it that way puts
# the binary outside nix's view and breaks at work when public npm is
# blocked.  Building it from source via `buildNpmPackage' gives us:
#   - a nix-store-resident binary (no global `npm install')
#   - reproducible build keyed on `npmDepsHash' (all dep tarballs are
#     content-addressed and cached in the nix store after first build)
#   - cross-machine sharability via a binary cache (push the built
#     derivation to cachix/etc. and locked-down machines pull it
#     without ever hitting registry.npmjs.org)

let
  version = "0.60.0";

  srcRaw = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "claude-agent-acp";
    rev = "v${version}";
    sha256 = "sha256-idyZcd8KD+bhAlKqqaTS6X8DcNjAzluln8it1V0vyUk=";
  };

in buildNpmPackage rec {
  pname = "claude-agent-acp";
  inherit version;

  # Rewrite the lockfile's resolved URLs from registry.npmjs.org to
  # registry.npmmirror.com (Alibaba's full public npm mirror) BEFORE
  # dependency fetching.  The work network's Zscaler policy blocks the
  # npmjs.org DOMAIN but allows the mirror (verified 2026-07-20), so
  # this makes the package buildable on every host with zero
  # registry.npmjs.org contact.  Safe: npm verifies each tarball
  # against the per-package `integrity' sha512 in the lockfile, so the
  # mirror can only serve bit-identical content or fail the build.
  # NOTE: the rewrite changes `npmDepsHash' (URLs are baked into the
  # dep cache) — recompute it on any version bump AFTER this wrapper.
  src = runCommand "claude-agent-acp-${version}-src-mirrored" { } ''
    cp -r ${srcRaw} $out
    chmod -R u+w $out
    substituteInPlace $out/package-lock.json \
      --replace-fail "https://registry.npmjs.org/" "https://registry.npmmirror.com/"
  '';

  # Content hash of all npm deps from package-lock.json — bump this when
  # the version changes (build will fail and print the new hash).
  npmDepsHash = "sha256-cVGpH/mAPCzHP+4SvaCw6aRcfs7b36Djb3goEwCRqO8=";

  # `npm run build' just runs `tsc' to compile src/*.ts -> dist/*.js.
  # buildNpmPackage runs this automatically as the build phase, but
  # spelling it out keeps intent visible.
  npmBuildScript = "build";

  inherit nodejs;

  meta = with lib; {
    description = "ACP-compatible bridge that exposes Claude Code via the Agent Client Protocol";
    homepage = "https://github.com/agentclientprotocol/claude-agent-acp";
    license = licenses.asl20;
    mainProgram = "claude-agent-acp";
    platforms = platforms.unix;
  };
}
