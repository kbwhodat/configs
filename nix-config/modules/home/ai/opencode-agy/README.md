# opencode-agy

OpenCode V2 provider for the official Antigravity ACP server and your Google AI Pro login.

1. Install `agy-acp-server` (both binaries must stay together); see [Nix wiring](NIX-SNIPPET.md).
2. Link this directory to `~/.config/opencode/plugins/agy` and add `"./plugins/agy"` to `plugins`.
3. Run `opencode auth login` and choose Antigravity, or `bun run bin/login.ts`.
4. Select `agy/argon`, optionally `#low`, `#medium` (default), or `#high` in an agent model.

Set `providers.agy.settings.serverPath` or `OPENCODE_AGY_ACP_SERVER` to override the executable.
Native Antigravity tools are off by default; OpenCode tools and permissions are bridged over local MCP.
`nativeTools: true` enables the native harness explicitly. Catalog models appear under their real ids
after the first authenticated session. Argon ids/thinking levels still need post-login confirmation.

No tokens are read or imported. Durable session ids/hashes and the model catalog use plugin storage.
Primary turns continue across tool steps; utility calls use isolated tool-free ACP sessions.
Run `bunx tsc --noEmit`, `bun test`, and `bun run bin/login.ts --dry-run` to verify without login.
