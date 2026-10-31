# opencode-agy: Gemini 4 Argon as a first-class OpenCode v2 provider

Goal: an OpenCode V2 plugin that registers provider `agy` whose models run through Google's
**official Antigravity ACP server** (`agy_acp_server.par`) using the user's own Google AI Pro login.
Parity target is OpenCode's built-in `claude-agent` provider (reference source at
`/tmp/agy-src.SAhG/opencode-claude-agent/claude-agent/`, read it; mirror its structure and names).
Agents can then set `model = "agy/argon"` and everything works: streaming text, reasoning, OpenCode
tools and permissions, effort variants, images, usage, session continuation, login via `opencode auth`.

Policy constraint (hard): never read, copy or reuse OAuth tokens from the ACP server, Gemini CLI or
Antigravity. We only drive the official server over its ACP stdio protocol. The server does its own
login and stores its own credentials under `~/.gemini/antigravity-acp/`.

## Reference material (already on disk, read before coding)

- `/tmp/agy-src.SAhG/opencode-claude-agent/claude-agent/**` — claude-agent provider (the model to copy).
- `/tmp/agy-src.SAhG/plugin-sdk/package/dist/**/*.d.ts` — `@opencode/plugin` 2.2.5 typings. Both the
  promise API (`dist/*.d.ts`, `Plugin.define`) and the Effect API (`dist/effect/*.d.ts`). Check which
  one exposes `provider.transform`, `aisdk.hook("sdk")`, `integration.transform`, `session.hook`,
  `permission`, `storage`. Prefer the promise API if it has them all, else use the Effect API like
  claude-agent does.
- `/tmp/agy-src.SAhG/schema/package/dist/{provider,model}.d.ts` — `Provider.Info`, `Model.Info`.
- `/tmp/agy-src.SAhG/acp-sdk/package/dist/v1/**/*.d.ts` — ACP v1 types (use for shapes only; do not
  depend on the package at runtime, hand-roll the JSON-RPC client).
- `/tmp/agy-src.SAhG/acp-bin/x/agy_acp_server.par` (+ `localharness_external` beside it) — the server.
  `strings` it to discover: the `_meta.antigravity` shapes accepted by `session/new` (system prompt
  append, tier), config option ids (`model`, effort/thinking), whether native tools can be disabled,
  and MCP server config shape. Keep the two binaries side by side.
- `~/.config/opencode/plugins/rtk.ts` — a local V2 plugin that already loads; see how it imports
  `@opencode/plugin` (there is a `package.json` in `~/.config/opencode`).
- Docs: https://opencode.ai/v2/docs/build/plugins/ , /build/plugins/server , /build/plugins/effect ,
  https://agentclientprotocol.com/llms.txt (prompt-turn, tool-calls, session-setup, content,
  session config options, usage_update, request_permission).

## Known ACP server facts (verified 2026-10-31 on v1.4.5 darwin-arm64)

- stdio ndjson JSON-RPC 2.0. `initialize` → `protocolVersion 1`, `agentCapabilities.loadSession true`,
  `promptCapabilities {image, audio, embeddedContext}`, `mcpCapabilities {http, sse}` (no stdio MCP),
  `sessionCapabilities {list, additionalDirectories, resume}`, `auth.logout`, `_meta.antigravity {tier,
  systemPrompt.append}`. `authMethods`: `oauth-personal | oauth-business | gemini-api-key | agent-platform`.
- Settings file `~/.gemini/antigravity-acp/settings.json` = `{"auth":{"type":"oauth-personal"}}`.
- Model selection: `session/set_config_option {sessionId, configId:"model", value}`; unknown → -32602.
  Catalog comes back in `session/new` result `configOptions`. Expected ids look like
  `gemini-4-argon-high`, `gemini-4-argon-medium`, `gemini-4-argon-low` (verify after login).
- Updates: `agent_message_chunk` (text), `agent_thought_chunk` (reasoning), `tool_call`,
  `tool_call_update`, `usage_update`, `current_mode_update`, `config_option_update`.
- Linux builds need a `--uid=` arg; macOS does not.

## Architecture (mirror claude-agent file layout)

```
opencode-agy/
  package.json          name "opencode-agy", type module, exports "." -> src/index.ts
  tsconfig.json
  src/index.ts          Plugin.define({ id: "agy", setup })  — wires everything below
  src/provider.ts       PACKAGE id, provider.transform: add provider "agy" + models
  src/aisdk.ts          aisdk.hook("sdk") -> { languageModel(id) => AgyLanguageModel }
  src/integration.ts    integration.transform: login method that runs the ACP authenticate flow
  src/session.ts        session hooks: model.request (kind+session headers), retry off, context
  src/instructions.ts   collect OpenCode system prompt/instructions (copy claude-agent/instructions.ts)
  src/language-model/   agy-language-model.ts, convert-acp-stream.ts, convert-to-acp-prompt.ts,
                        request-kind.ts, usage.ts, system-prompt.ts, agy-error.ts
  src/tools/            mcp-server.ts (hand-rolled Streamable HTTP MCP), pending.ts, names.ts, result.ts
  src/acp/              process.ts (spawn + JSON-RPC client), session.ts (one ACP session: prompt,
                        readStep, cancel), sessions.ts (registry per OpenCode session), io.ts (paths)
  src/sync/             record.ts, fingerprint.ts, decide.ts (simplified: fresh / continue / changed)
  bin/login.ts          standalone: spawn server, initialize, authenticate(oauth-personal), print outcome
  README.md             short: install, login, settings, variants
```

Runtime deps: none beyond what `@opencode/plugin` provides. Use `node:child_process`, `node:http`,
`node:crypto`, `node:readline`. Type-only imports from `@ai-sdk/provider` and `@opencode/plugin`.

### ACP process (`acp/process.ts`)
- One long-lived server process per OpenCode server (ACP multiplexes sessions). Spawn lazily on first
  use, cwd = OpenCode directory, stdin/stdout ndjson, stderr to OpenCode log.
- Server path: settings `serverPath` (from provider options) → env `OPENCODE_AGY_ACP_SERVER` →
  `agy-acp-server` on PATH → `~/.local/share/agy-acp/agy_acp_server.par`.
- Client-side request handlers: `session/request_permission` → OpenCode permission ask (map the
  option kinds allow_once / allow_always / reject_once; denied → pick the reject option);
  `fs/read_text_file`, `fs/write_text_file`, `terminal/*` → do **not** advertise these capabilities
  (clientCapabilities fs false, terminal false) so the server uses its own harness.
- Idle stop after 5 min with no active sessions; 10 s handover on plugin reload like claude-agent.
- `initialize` once; if `session/new` fails with auth_required surface a clear error:
  "Run `opencode auth login` and pick Antigravity (agy), or `bun run bin/login.ts`".

### Tool bridge (`tools/mcp-server.ts`, `tools/pending.ts`)
- node:http server on 127.0.0.1, random port, started with the ACP process. Path `/s/<opencodeSessionID>`.
  Streamable HTTP MCP, JSON responses (no SSE needed): `initialize` (protocolVersion "2025-06-18",
  capabilities.tools.listChanged true), `notifications/initialized` → 202, `tools/list` → the tools of
  the current doStream for that session (names via `ToolNames.short`, same 64-char rule as claude-agent),
  `tools/call` → register pending call, emit AI SDK `tool-call` to the active stream, end the OpenCode
  step with finishReason `tool-calls`, await the result promise (resolved by the next doStream that
  carries the tool result), return `CallToolResult`. GET → 405. `ping` → {}.
- Pass to `session/new`: `mcpServers: [{ type: "http", name: "opencode", url, headers: [] }]`
  (confirm exact shape from the ACP SDK types / server strings).
- Side calls (title/summary/generate/compaction) get no tools.
- If a second MCP call arrives while the step is already ended, queue it and emit it at the start of
  the next step (serial steps are fine).
- Native Antigravity tool calls (reported via `tool_call` updates that did not come through our MCP
  server) are rendered as provider-executed parts: `tool-call {providerExecuted: true}` then on
  `tool_call_update` completed/failed a `tool-result {providerExecuted: true}` with the content.
  If the server strings show a way to disable native tools from `session/new` `_meta`, use it and
  make it the default (`settings.nativeTools: false`), so OpenCode's tools are the only tools.

### Language model (`language-model/agy-language-model.ts`)
- `LanguageModelV3`, `specificationVersion: "v3"`, `provider: "agy"`, `supportedUrls: {}`.
- Kind from headers set in the `model.request` hook (copy claude-agent `request-kind.ts`:
  primary / title / summary / generate / compaction, plus session id header). Primary → registry
  session; side kinds → throwaway ACP session, prompt rendered as a text transcript, no tools, closed
  after the call.
- `doStream`: ReadableStream of stream parts; `doGenerate` collects doStream.
- Abort signal → `session/cancel`.
- Stream mapping: `agent_message_chunk` → text-start/delta/end (one id per contiguous run);
  `agent_thought_chunk` → reasoning-*; `usage_update` → usage snapshot (input/cache/output/reasoning
  where available); prompt result `stopReason` → finish (end_turn → stop, max_tokens → length,
  cancelled → stop, refusal → content-filter); JSON-RPC error → `error` part with a readable message.

### Prompt conversion (`language-model/convert-to-acp-prompt.ts`)
- Copy claude-agent `convert-to-claude-message.ts`: earlier turns become `<user>…</user>`,
  `<assistant>…</assistant>`, `<tool-call>`, `<tool-result>` text blocks; images become ACP
  `{type:"image", data: base64, mimeType}`; PDFs become `{type:"resource", resource:{blob, mimeType, uri}}`
  if embeddedContext is supported, else an error.
- System prompt: OpenCode's system messages + agent prompt + instructions go to `session/new`
  `_meta.antigravity.systemPrompt.append` (verify shape). Add this runtime note at the top:
  `<runtime_info>You are running in OpenCode through the Antigravity harness. Mention this only when asked.</runtime_info>`
  Also add: "Verify any URL, file, product or name the user gives you before reasoning about it; never
  substitute a similar-looking one."

### Sessions (`acp/sessions.ts`, `sync/*`)
- Registry keyed by OpenCode session id. Record in `ctx.storage` under `sessions/<id>`:
  `{ acpSessionID, history: [{hash}], interrupted }`. Lock per entry.
- Decide per request (simplified `decide.ts`): hash message groups (user / assistant+tool groups) like
  claude-agent `fingerprint.ts`. All saved hashes match a prefix → `continue` (send only the new
  content). Saved empty → `fresh`. Mismatch → `changed` → new ACP session seeded with the full
  transcript as the first prompt. After the process restarts, try `session/load` with the saved id
  (swallow the replayed history updates until the load returns); on error → fresh.
- Tool continuation: when the previous step ended at a tool boundary and the new prompt carries the
  results for the pending ids, resolve them and keep reading the same ACP turn. If results are missing
  or the turn was aborted → cancel the ACP turn, start a new one.
- Model and effort applied via `session/set_config_option` before each prompt when they changed.

### Provider + models (`provider.ts`)
- Provider id `agy`, name "Antigravity (Google AI Pro)", `package` set the same way claude-agent sets
  `info.package` (`Provider.aisdk(PACKAGE)` or equivalent), so `aisdk.hook("sdk")` matches on
  `evt.package`.
- Baseline models (static, always present): `argon` → name "Gemini 4 Argon", maps to the catalog id
  for the chosen effort: variants `low | medium | high`, default `medium`, each variant
  `{ id, settings: { effort } }`. Also `flash` → Gemini 3.8 Flash if present in the catalog.
  cost all 0 (subscription). limit: context 1_000_000, output 65_536. capabilities: reasoning true,
  toolcall true, attachment true, temperature false.
- After each `session/new`, write the catalog to storage `catalog` and expose every catalog model under
  its own id too, so `agy/gemini-4-argon-high` works directly.
- Mapping rule for `argon` + effort: find catalog id `gemini-4-argon-<effort>`; if the catalog instead
  has a single `gemini-4-argon` plus an effort/thinking config option, set that option. Decide after
  reading the real catalog; keep the mapping in one function.

### Integration (`integration.ts`)
- Add provider `agy` to `opencode auth login` with one method that runs the ACP `authenticate`
  flow (`methodId: "oauth-personal"`), writes `~/.gemini/antigravity-acp/settings.json` if missing,
  and reports success. Mirror claude-agent `integration.ts` for the method shape (external/command).
- `bin/login.ts` does the same standalone for testing.

### Session hooks (`session.ts`)
- Copy claude-agent: `model.request` sets `x-opencode-agy-kind` and `x-opencode-session-id` headers;
  `retry` → no retries for agy; `context` → drop maxTokens the way claude-agent does.

## Nix wiring (write files, do not edit opencode.nix yourself)
- `agy-acp-server.nix`: `stdenvNoCC.mkDerivation` fetching
  `https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-1.4.5-darwin-arm64.zip`
  (sha256 `886fff7767d08994ca39eb02c3d01a7532c7325a94aa33aaf52d52068733284f`), `nativeBuildInputs = [unzip]`,
  install both files into `$out/libexec/agy-acp/`, wrapper `$out/bin/agy-acp-server` that execs the
  `.par` from that dir. Mark `dontStrip`, `dontPatchShebangs`, `dontFixup`.
- `NIX-SNIPPET.md`: the exact lines to add to `opencode.nix`: `home.file` for the plugin dir →
  `~/.config/opencode/plugins/agy`, `plugins` entry for it (check how a local plugin directory is
  referenced in V2 config), `provider.agy.options.serverPath`, and the `agy` login note.

## Verification (do these, report output)
1. `bun install` in the plugin dir (only if a package is actually needed) and `bunx tsc --noEmit`.
2. `bun run bin/login.ts --dry-run` must reach `initialize` and print the auth methods.
3. With `OPENCODE_AGY_ACP_SERVER=/tmp/agy-src.SAhG/acp-bin/x/agy_acp_server.par` and the plugin
   linked into `~/.config/opencode/plugins/agy`, `opencode models | grep agy` lists `agy/argon`.
4. `tail -n 50 ~/.local/share/opencode/log/opencode.log` shows the plugin loaded without errors.
Login and the real Argon prompt test need the user (browser); stop there and report.

## Report format (keep it under 60 lines)
Files written; what is verified (with the exact commands); the real `_meta` / config option / MCP
shapes you found in the binary; open questions; anything you could not do.
