{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs
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

buildNpmPackage rec {
  pname = "claude-agent-acp";
  version = "0.60.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "claude-agent-acp";
    rev = "v${version}";
    sha256 = "sha256-idyZcd8KD+bhAlKqqaTS6X8DcNjAzluln8it1V0vyUk=";
  };

  # Content hash of all npm deps from package-lock.json — bump this when
  # the version changes (build will fail and print the new hash).
  npmDepsHash = "sha256-dJeUPTcGN616YVKLcsiGgSn8wb7NhJZuZmPRHeUxR4U=";

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
