import { Plugin } from "@opencode/plugin"
import { AcpProcess, HANDOVER_MS } from "./acp/process.js"
import { Status } from "./acp/status.js"
import { message } from "./acp/errors.js"
import { Sessions } from "./acp/sessions.js"
import { ToolServer } from "./tools/mcp-server.js"
import * as Provider from "./provider.js"
import * as AISDK from "./aisdk.js"
import * as Integration from "./integration.js"
import * as Session from "./session.js"
import * as Instructions from "./instructions.js"

interface Runtime { sessions: Sessions; status: Status; owners: number; timer?: ReturnType<typeof setTimeout>; ctx: Plugin.Context }
// Symbol.for survives module reloads; directory scoping avoids sharing tool bindings across projects.
const key = Symbol.for("opencode-agy.runtimes.v1")
const host = globalThis as typeof globalThis & { [key]?: Map<string, Runtime> }
const runtimes = host[key] ??= new Map<string, Runtime>()
export default Plugin.define({
  id: "agy",
  async setup(ctx) {
    if (ctx.location.workspaceID !== undefined) return
    const directory = ctx.location.directory
    const catalog = await Provider.register(ctx)
    let runtime = runtimes.get(directory)
    if (!runtime) {
      const process = new AcpProcess({ directory,
        serverPath: typeof ctx.options.serverPath === "string" ? ctx.options.serverPath : undefined,
        // Do not copy server stderr into logs: OAuth URLs and secrets can appear there.
        log: () => console.debug("[agy] ACP stderr received (content suppressed)"),
        permission: async (request) => {
          const current = runtimes.get(directory)
          const sessionID = current?.sessions.owner(request.sessionId)
          if (!current || !sessionID) return "reject_once"
          try {
            await current.ctx.permission.assert({ sessionID: sessionID as Parameters<Plugin.Context["permission"]["assert"]>[0]["sessionID"], action: "agy.native", resources: [String(request.toolCall.title ?? "Antigravity native tool")], metadata: { toolCall: request.toolCall } })
            return "allow_once"
          } catch { return "reject_once" }
        },
      })
      const status = new Status(process)
      const sessions = new Sessions({ process, directory, storage: ctx.storage, tools: new ToolServer(), catalog: async (info) => {
        const init = await process.initialize()
        await status.report({ type: "ready", models: Provider.catalog(info).models, tier: info._meta?.antigravity?.tier, protocolVersion: init.protocolVersion })
      } })
      runtime = { sessions, status, ctx, owners: 0 }
      runtimes.set(directory, runtime)
    }
    clearTimeout(runtime.timer)
    runtime.ctx = ctx; runtime.owners++
    const unsubscribe = runtime.status.subscribe(async (state) => {
      if (state.type === "ready") await catalog({ models: state.models })
    })
    await AISDK.register(ctx, { run: async (request, signal) => {
      if (typeof request.settings.serverPath === "string") runtime.sessions.options.process.options.serverPath = request.settings.serverPath
      try { await runtime.sessions.run(request, signal) }
      catch (error) {
        if (!signal.aborted) await runtime.status.report({ type: "failed", message: message(error) })
        throw error
      }
    } })
    const disconnect = await Integration.register(ctx, runtime.status)
    await Session.register(ctx)
    await Instructions.register(ctx)
    const events = new AbortController()
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: events.signal, types: ["session.execution.succeeded", "session.execution.failed", "session.execution.interrupted"] })) runtime.sessions.idle(event.data.sessionID)
    })().catch(() => {})
    console.info("[agy] plugin loaded: Antigravity provider registered")
    void runtime.status.refresh().catch(() => console.warn("[agy] status refresh failed"))
    return () => {
      disconnect(); unsubscribe()
      events.abort()
      if (--runtime.owners) return
      runtime.timer = setTimeout(() => {
        runtimes.delete(directory)
        void runtime.sessions.close().catch(() => console.warn("[agy] cleanup failed"))
      }, HANDOVER_MS)
      runtime.timer.unref()
    }
  },
})
