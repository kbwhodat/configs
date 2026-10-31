import { AcpProcess, type ObjectValue } from "./process.js"
import { PendingTools, type Call } from "../tools/pending.js"
import type { McpServerConfig } from "../tools/mcp-server.js"

export interface ConfigOption {
  id: string; name: string; type: string; category?: string; currentValue: string | boolean
  options?: Array<{ value: string; name: string; description?: string } | { group: string; options: Array<{ value: string; name: string }> }>
}
export interface SessionInfo {
  sessionId: string
  configOptions?: ConfigOption[]
  models?: { currentModelId: string; availableModels: Array<{ modelId: string; name: string; description?: string }> }
  _meta?: { antigravity?: { tier?: { name: string; id: string; upgradeUri: string } } }
}
export type ContentBlock = { type: "text"; text: string } | { type: "image"; data: string; mimeType: string }
  | { type: "resource"; resource: { uri: string; mimeType: string; blob: string } }
export interface PromptResult { stopReason: string; usage?: ObjectValue }
export type SessionEvent = { type: "update"; update: ObjectValue }
  | { type: "tool"; call: Call } | { type: "result"; result: PromptResult }
export interface SessionOptions {
  directory: string; system: string; mcpServers?: McpServerConfig[]; nativeTools?: boolean
}
export function sessionParams(options: SessionOptions) {
  return {
    cwd: options.directory, mcpServers: options.mcpServers ?? [],
    _meta: { antigravity: {
      systemPrompt: { append: options.system },
      ...(options.nativeTools === true ? {} : { enabledTools: [] }),
      eagerMcpServers: ["opencode"],
    } },
  }
}
export class AcpSession {
  readonly pending: PendingTools
  readonly generation: number
  private queue: SessionEvent[] = []
  private wake?: () => void
  private failure?: Error
  private turn?: Promise<void>
  private finished = true
  private closed = false
  private reading = false
  private readonly unsubscribe: Array<() => void> = []
  private readonly release: () => void
  private constructor(readonly process: AcpProcess, readonly info: SessionInfo, pending: PendingTools) {
    this.pending = pending
    this.generation = process.generation
    this.release = process.retain()
    this.unsubscribe.push(process.onNotification((method, params) => {
      if (method !== "session/update" || params.sessionId !== this.id || !params.update) return
      const update = params.update as ObjectValue
      if (update.sessionUpdate === "config_option_update") this.info.configOptions = update.configOptions as ConfigOption[]
      if (!this.finished) this.queue.push({ type: "update", update })
      this.wake?.()
    }), process.onExit((error) => { this.failure = error; this.wake?.() }), pending.onCall(() => this.wake?.()))
  }
  static async open(process: AcpProcess, options: SessionOptions, pending = new PendingTools(), loadID?: string) {
    const params = sessionParams(options)
    const info = loadID
      ? { ...await process.request<SessionInfo>("session/load", { ...params, sessionId: loadID }), sessionId: loadID }
      : await process.request<SessionInfo>("session/new", params)
    return new AcpSession(process, info, pending)
  }
  static async fork(process: AcpProcess, sourceID: string, options: SessionOptions, pending = new PendingTools()) {
    const info = await process.request<SessionInfo>("session/fork", {
      sessionId: sourceID, cwd: options.directory, mcpServers: options.mcpServers ?? [],
    })
    // Some servers register the ACP method but return {} from an unimplemented handler.
    if (!info || typeof info.sessionId !== "string" || !info.sessionId || info.sessionId === sourceID) {
      throw new Error("Antigravity session/fork did not return a new sessionId")
    }
    return new AcpSession(process, info, pending)
  }
  get id() { return this.info.sessionId }
  get running() { return !this.finished }
  get ended() { return this.closed || !!this.failure || this.generation !== this.process.generation }
  async configure(model: string, effort?: string) {
    const selection = selectModel(model, effort, this.info)
    for (const [configId, value] of selection) {
      if (this.info.configOptions?.find((option) => option.id === configId)?.currentValue === value) continue
      const response = await this.process.request<{ configOptions?: ConfigOption[] }>("session/set_config_option", { sessionId: this.id, configId, value })
      // Merge by id: a partial response must not drop the model catalog we read at session/new.
      const merged = new Map((this.info.configOptions ?? []).map((option) => [option.id, option] as const))
      for (const option of response.configOptions ?? []) {
        const previous = merged.get(option.id)
        merged.set(option.id, { ...previous, ...option, options: option.options ?? previous?.options })
      }
      this.info.configOptions = [...merged.values()]
    }
  }
  begin(prompt: ContentBlock[]) {
    if (this.ended || !this.finished) throw new Error("Antigravity session is unavailable or still running")
    this.finished = false; this.queue = []
    this.turn = this.process.request<PromptResult>("session/prompt", { sessionId: this.id, prompt }).then((result) => {
      this.queue.push({ type: "result", result })
    }, (error) => { this.failure = error instanceof Error ? error : new Error(String(error)) }).finally(() => {
      this.finished = true; this.wake?.()
    })
  }
  /** Tool boundary parks the ACP prompt; subsequent reads resume the same turn. */
  async readStep(emit: (event: SessionEvent) => void, signal?: AbortSignal): Promise<"tools" | PromptResult> {
    if (this.reading) throw new Error("Concurrent Antigravity session read")
    this.reading = true
    const abort = () => { void this.cancel().catch(() => {}); this.wake?.() }
    signal?.addEventListener("abort", abort, { once: true })
    try {
      while (true) {
        if (signal?.aborted) throw signal.reason ?? new Error("Aborted")
        if (this.failure) throw this.failure
        const event = this.queue.shift()
        if (event) {
          emit(event)
          if (event.type === "result") return event.result
          continue
        }
        const call = this.pending.take()
        if (call) { emit({ type: "tool", call }); return "tools" }
        if (this.finished) throw new Error("No Antigravity turn to read")
        await new Promise<void>((resolve) => { this.wake = resolve })
        this.wake = undefined
      }
    } finally { this.reading = false; signal?.removeEventListener("abort", abort) }
  }
  async cancel() {
    if (!this.finished && !this.ended) {
      this.process.notify("session/cancel", { sessionId: this.id })
      let timer: ReturnType<typeof setTimeout> | undefined
      try {
        await Promise.race([this.turn, new Promise<never>((_, reject) => {
          timer = setTimeout(() => reject(new Error("ACP cancellation timed out")), 10_000)
        })])
      } catch (error) { this.failure = error instanceof Error ? error : new Error(String(error)); throw error }
      finally { clearTimeout(timer) }
    }
    this.pending.clear()
  }
  async close() {
    if (this.closed) return
    try {
      await this.cancel()
      if (!this.ended) await this.process.request("session/close", { sessionId: this.id })
    } finally {
      this.closed = true; this.pending.clear()
      for (const dispose of this.unsubscribe) dispose()
      this.release()
    }
  }
}
/** Concrete ids remain valid even when configOptions groups them by family. */
// TODO: confirm the Argon catalog ids and thinking_level values after the user's first login.
export function selectModel(model: string, effort = "medium", info: SessionInfo): Array<[string, string]> {
  if (!["low", "medium", "high"].includes(effort)) throw new Error("Antigravity effort must be low, medium or high")
  const concrete = info.models?.availableModels.map((item) => item.modelId) ?? []
  const modelOption = info.configOptions?.find((option) => option.id === "model")
  const flat = (modelOption?.options ?? []).flatMap((option) => "value" in option ? [option.value] : option.options.map((item) => item.value))
  const available = [...concrete, ...flat]
  if (model === "argon") {
    const id = `gemini-4-argon-${effort}`
    if (available.includes(id)) return [["model", id]]
    if (available.includes("gemini-4-argon")) {
      if (!info.configOptions?.some((option) => option.id === "thinking_level")) throw new Error("Argon catalog has no thinking_level option")
      return [["model", "gemini-4-argon"], ["thinking_level", effort]]
    }
    throw new Error("Gemini 4 Argon is not available in the Antigravity model catalog")
  }
  if (model === "flash") {
    const id = available.find((id) => /^gemini-3[.-]8-flash/.test(id))
    if (!id) throw new Error("Gemini 3.8 Flash is not available in the Antigravity model catalog")
    return withThinking(id, effort, info)
  }
  return withThinking(model, effort, info)
}
// Family ids (gemini-4-argon, gemini-3.8-flash) take their effort from thinking_level; ids with a built-in suffix ignore it.
function withThinking(id: string, effort: string, info: SessionInfo): Array<[string, string]> {
  const hasOption = info.configOptions?.some((option) => option.id === "thinking_level")
  if (!hasOption || /-(low|medium|high)$/.test(id)) return [["model", id]]
  return [["model", id], ["thinking_level", effort]]
}
