import type { Plugin } from "@opencode/plugin"
import { fileURLToPath } from "node:url"
import { ID } from "./provider.js"
import type { Status, State } from "./acp/status.js"
import { MISSING_HELP } from "./acp/errors.js"
export const METHOD_ID = "oauth-personal"
export function problem(state: State) {
  if (state.type === "missing") return { status: "needs_auth" as const, message: MISSING_HELP }
  if (state.type === "failed") return { status: "needs_auth" as const, message: state.message }
  return undefined
}
export async function register(ctx: Plugin.Context, status: Status) {
  await ctx.integration.transform((editor) => {
    editor.method.update({ integrationID: ID, method: {
      id: METHOD_ID, type: "command", label: "Google AI Pro login (official Antigravity ACP)",
      command: ["bun", "run", fileURLToPath(new URL("../bin/login.ts", import.meta.url))],
    } })
    editor.update(ID, (integration) => { integration.name = "Antigravity (Google AI Pro)" })
  })
  const publish = async (state: State) => {
    if (state.type === "checking") return
    const connection = await ctx.integration.connection.active(ID)
    if (connection) await ctx.integration.connection.status({ integrationID: ID, connection, status: problem(state) })
  }
  const unsubscribe = status.subscribe(publish)
  await publish(status.state)
  const events = new AbortController()
  void (async () => {
    for await (const event of ctx.event.subscribe({ signal: events.signal, types: ["credential.switched"] })) {
      if (event.data.integrationID === ID) await status.refresh()
    }
  })().catch(() => { if (!events.signal.aborted) console.warn("[agy] connection status listener failed") })
  return () => { unsubscribe(); events.abort() }
}
