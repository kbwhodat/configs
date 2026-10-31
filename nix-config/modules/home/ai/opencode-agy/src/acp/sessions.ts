import type { LanguageModelV3Prompt, LanguageModelV3TextPart, LanguageModelV3ToolCallPart } from "@ai-sdk/provider"
import type { Request, Dependencies } from "../language-model/agy-language-model.js"
import { content } from "../language-model/convert-to-acp-prompt.js"
import { PendingTools } from "../tools/pending.js"
import { ToolServer, type McpServerConfig } from "../tools/mcp-server.js"
import { ToolResult } from "../tools/result.js"
import { groups } from "../sync/fingerprint.js"
import { decide } from "../sync/decide.js"
import { make, type Record, type Storage } from "../sync/record.js"
import { AcpProcess, IDLE_MS } from "./process.js"
import { AcpSession, type SessionInfo } from "./session.js"

interface Entry {
  lock: Promise<void>; session?: AcpSession; record?: Record; launch?: string
  idle?: ReturnType<typeof setTimeout>; active?: AbortController
}
export interface Options {
  process: AcpProcess; tools: ToolServer; storage: Storage; directory: string
  catalog: (info: SessionInfo) => Promise<void>
}
/** Promise-chain mutexes serialize only requests for the same OpenCode session. */
export class Sessions implements Dependencies {
  private entries = new Map<string, Entry>()
  private temporary = new Set<Entry>()
  private owners = new Map<string, string>()
  private records: ReturnType<typeof make>
  constructor(readonly options: Options) { this.records = make(options.storage) }
  owner(acpID: string) { return this.owners.get(acpID) }
  private async stop(entry: Entry, id?: string) {
    const session = entry.session
    entry.session = undefined
    if (session) {
      this.owners.delete(session.id)
      try { await session.close() } finally { if (id) this.options.tools.unbind(id) }
    }
  }
  private arm(entry: Entry, id: string) {
    clearTimeout(entry.idle)
    entry.idle = setTimeout(() => {
      const task = entry.lock.then(() => this.stop(entry, id))
      entry.lock = task.catch(() => {})
    }, IDLE_MS)
    entry.idle.unref()
  }
  idle(id: string) {
    const entry = this.entries.get(id)
    if (entry && !entry.active) this.arm(entry, id)
  }
  async run(request: Request, signal: AbortSignal): Promise<void> {
    const id = request.sessionID
    let entry = id ? this.entries.get(id) : undefined
    if (!entry) {
      entry = { lock: Promise.resolve() }
      if (id) this.entries.set(id, entry)
      else this.temporary.add(entry)
    }
    const current = entry
    const task = current.lock.then(async () => {
      signal.throwIfAborted()
      clearTimeout(current.idle)
      const controller = new AbortController()
      current.active = controller
      const combined = AbortSignal.any([signal, controller.signal])
      try { await this.turn(current, request, combined) }
      finally {
        current.active = undefined
        if (!id) { await this.stop(current); this.temporary.delete(current) }
        else if (!current.session?.pending.size) this.arm(current, id)
      }
    })
    current.lock = task.catch(() => {})
    await task
  }
  private async snapshot(entry: Entry, request: Request, pending: PendingTools, mcpServers: McpServerConfig[]) {
    const sourceID = request.sourceID
    if (!sourceID || sourceID === request.sessionID || request.kind === "title") return
    const source = this.entries.get(sourceID)
    const copy = async () => {
      try {
        const record = source?.record ?? await this.records.get(sourceID)
        const acpID = source?.session && !source.session.ended ? source.session.id : record?.acpSessionID
        if (!acpID) return
        const decision = decide(request.prompt, record)
        // A primary fork must copy the entire saved prefix: ACP cannot truncate history.
        if (request.sessionID && (decision.kind !== "continue" || !record?.history.length)) return
        // Side calls append their instruction to the transcript. Instruction-only calls
        // also work; a rewritten utility transcript must never be replayed into the fork.
        const start = decision.kind === "continue" ? decision.start : request.prompt.findLastIndex((message) => message.role === "user")
        if (start < 0) return
        // Validate attachments before creating the native fork.
        const init = await this.options.process.initialize()
        content(request.prompt.slice(start), init.agentCapabilities.promptCapabilities)
        try {
          entry.session = await AcpSession.fork(this.options.process, acpID, {
            directory: this.options.directory, system: request.system, mcpServers,
          }, pending)
        } catch { return }
        entry.record = { acpSessionID: entry.session.id, history: decision.kind === "continue" ? record!.history.map(({ hash }) => ({ hash })) : [], interrupted: false }
        if (request.sessionID) await this.records.set(request.sessionID, entry.record)
        return start
      } finally {
        // Compaction ends the old context even when forking fails and we fall back.
        if (request.kind === "compaction" && source) await this.stop(source, sourceID)
      }
    }
    // Only hold the source lock while copying, never during side-call inference.
    if (!source) return copy()
    const task = source.lock.then(copy)
    source.lock = task.then(() => {}, () => {})
    return task
  }
  private async turn(entry: Entry, request: Request, signal: AbortSignal) {
    const { process, tools, directory } = this.options
    const id = request.sessionID
    if (id && !entry.record) entry.record = await this.records.get(id)
    const launch = JSON.stringify([request.system, request.settings.nativeTools === true])
    if (entry.session?.ended || (entry.launch && entry.launch !== launch)) {
      await this.stop(entry, id)
      if (entry.launch !== launch) entry.record = undefined
    }
    const decision = decide(request.prompt, entry.record)
    let start = id ? decision.start : 0
    if (decision.kind !== "continue") {
      // session/fork copies full history; changed histories cannot be truncated and must rebuild.
      await this.stop(entry, id)
      entry.record = undefined
    }
    const init = await process.initialize()
    signal.throwIfAborted()
    if (!entry.session) {
      const pending = new PendingTools()
      const mcp = id ? [await tools.bind(id, { pending, tools: request.tools })] : []
      const params = { directory, system: request.system, mcpServers: mcp, nativeTools: id ? request.settings.nativeTools === true : false }
      if ((!id || decision.kind === "fresh") && !entry.record?.history.length) {
        const boundary = await this.snapshot(entry, request, pending, mcp)
        if (boundary !== undefined) start = boundary
      }
      const load = id && !entry.record?.interrupted && init.agentCapabilities.loadSession ? entry.record?.acpSessionID : undefined
      if (!entry.session && load) {
        try { entry.session = await AcpSession.open(process, params, pending, load) }
        catch { entry.record = undefined; start = 0 }
      }
      if (!entry.session) { start = 0; entry.session = await AcpSession.open(process, params, pending) }
      entry.launch = launch
      if (id) this.owners.set(entry.session.id, id)
      await this.options.catalog(entry.session.info)
    }
    const session = entry.session
    if (id) tools.update(id, request.tools)
    const reply: Array<LanguageModelV3TextPart | LanguageModelV3ToolCallPart> = []
    const emit: Request["emit"] = (event) => {
      if (event.type === "tool") reply.push({ type: "tool-call", toolCallId: event.call.id, toolName: event.call.name, input: event.call.input })
      if (event.type === "update" && event.update.sessionUpdate === "agent_message_chunk") {
        const block = event.update.content as { type?: string; text?: string } | undefined
        if (block?.type === "text" && block.text) reply.push({ type: "text", text: block.text })
      }
      request.emit(event)
    }
    let interrupted = true
    try {
      signal.throwIfAborted()
      // Native utility snapshots retain the source's model/thinking config for cache reuse.
      // Fresh utilities (including the cheap summary fallback) use their requested settings.
      if (id || !entry.record) await session.configure(request.model, request.effort)
      let continuation = false
      if (session.running) {
        const collected = ToolResult.collect(request.prompt, start)
        const waiting = session.pending.waiting
        if (waiting.length && !collected.aborted && collected.end === request.prompt.length && waiting.every((key) => collected.results.has(key))) {
          continuation = true
          for (const key of waiting) session.pending.resolve(key, collected.results.get(key)!.mcp)
        } else { await session.cancel(); start = decision.start }
      }
      if (!continuation) session.begin(content(request.prompt.slice(start), init.agentCapabilities.promptCapabilities))
      await session.readStep(emit, signal)
      interrupted = false
    } finally {
      if (interrupted) await session.cancel().catch(() => {})
      if (id) {
        const prompt: LanguageModelV3Prompt = [...request.prompt]
        if (!interrupted && reply.length) prompt.push({ role: "assistant", content: reply })
        entry.record = { acpSessionID: session.id, history: groups(prompt, entry.record?.history).map(({ hash }) => ({ hash })), interrupted }
        await this.records.set(id, entry.record)
      }
    }
  }
  async close() {
    const all = [...this.entries.entries(), ...[...this.temporary].map((entry) => [undefined, entry] as const)]
    for (const [, entry] of all) { clearTimeout(entry.idle); entry.active?.abort() }
    await Promise.all(all.map(async ([id, entry]) => { await entry.lock; await this.stop(entry, id) }))
    this.entries.clear(); this.temporary.clear()
    await this.options.tools.close()
    this.options.process.stop()
  }
}
