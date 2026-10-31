import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process"
import { accessSync, constants } from "node:fs"
import { homedir } from "node:os"
import { join, delimiter } from "node:path"
import { createInterface } from "node:readline"
import { AUTH_HELP, MISSING_HELP } from "./errors.js"
export { AUTH_HELP } from "./errors.js"

export type ObjectValue = Record<string, unknown>
export interface InitializeResult {
  protocolVersion: number
  authMethods: Array<{ id: string; name: string; description?: string }>
  agentCapabilities: {
    loadSession?: boolean
    promptCapabilities?: { image?: boolean; embeddedContext?: boolean; audio?: boolean }
    mcpCapabilities?: { http?: boolean; sse?: boolean }
    [key: string]: unknown
  }
  [key: string]: unknown
}
export interface PermissionRequest {
  sessionId: string
  toolCall: ObjectValue
  options: Array<{ optionId: string; name: string; kind: string }>
}
export interface Options {
  directory: string
  serverPath?: string
  log?: (line: string) => void
  permission?: (request: PermissionRequest) => Promise<"allow_once" | "allow_always" | "reject_once" | "reject_always">
}
// A cold start costs ~3 s (boot + session). 30 min covers a normal working pause.
export const IDLE_MS = 30 * 60_000
export const HANDOVER_MS = 10_000

export class RpcError extends Error {
  constructor(readonly code: number, message: string, readonly data?: unknown) {
    super(code === -32000 || /auth_required|authentication required/i.test(message) ? AUTH_HELP : message)
    this.name = "AgyRpcError"
  }
}
export function serverPath(explicit?: string): string {
  if (explicit) return explicit
  if (process.env.OPENCODE_AGY_ACP_SERVER) return process.env.OPENCODE_AGY_ACP_SERVER
  for (const directory of (process.env.PATH ?? "").split(delimiter)) {
    const file = join(directory, "agy-acp-server")
    try { accessSync(file, constants.X_OK); return file } catch { /* continue PATH lookup */ }
  }
  return join(homedir(), ".local/share/agy-acp/agy_acp_server.par")
}

/** One lazy, multiplexed transport. No credential files are accessed here. */
export class AcpProcess {
  private child?: ChildProcessWithoutNullStreams
  private startup?: Promise<InitializeResult>
  private sequence = 0
  private calls = new Map<number, { resolve: (value: unknown) => void; reject: (error: unknown) => void; cleanup: () => void }>()
  private listeners = new Set<(method: string, params: ObjectValue) => void>()
  private exits = new Set<(error: Error) => void>()
  private active = 0
  private idle?: ReturnType<typeof setTimeout>
  private handover?: ReturnType<typeof setTimeout>
  private owners = 0
  generation = 0
  constructor(readonly options: Options) {}

  attach(): () => void {
    this.owners++
    clearTimeout(this.handover)
    let disposed = false
    return () => {
      if (disposed) return
      disposed = true
      if (--this.owners === 0) this.handover = setTimeout(() => this.stop(), HANDOVER_MS)
    }
  }
  retain(): () => void {
    this.active++
    clearTimeout(this.idle)
    let released = false
    return () => {
      if (released) return
      released = true
      if (--this.active === 0) this.armIdle()
    }
  }
  private armIdle() {
    clearTimeout(this.idle)
    this.idle = setTimeout(() => this.stop(), IDLE_MS)
    this.idle.unref()
  }
  onNotification(listener: (method: string, params: ObjectValue) => void) {
    this.listeners.add(listener)
    return () => { this.listeners.delete(listener) }
  }
  onExit(listener: (error: Error) => void) {
    this.exits.add(listener)
    return () => { this.exits.delete(listener) }
  }
  initialize(): Promise<InitializeResult> {
    if (this.startup) return this.startup
    const executable = serverPath(this.options.serverPath)
    try { accessSync(executable, constants.X_OK) } catch {
      return Promise.reject(new Error(MISSING_HELP))
    }
    const child = spawn(executable, process.platform === "linux" ? [`--uid=${process.getuid?.() ?? 1000}`] : [], {
      cwd: this.options.directory, stdio: ["pipe", "pipe", "pipe"],
    })
    this.child = child
    this.generation++
    const lines = createInterface({ input: child.stdout, crlfDelay: Infinity })
    const errors = createInterface({ input: child.stderr, crlfDelay: Infinity })
    // Host logger is responsible for its own redaction; never log protocol frames.
    errors.on("line", (line) => this.options.log?.(line))
    lines.on("line", (line) => {
      try { void this.receive(JSON.parse(line)).catch(() => this.fail(child, new Error("ACP request handler failed"))) }
      catch { this.fail(child, new Error("ACP server sent invalid JSON")); child.kill() }
    })
    child.stdin.on("error", () => this.fail(child, new Error("ACP server input closed")))
    child.on("error", (error) => this.fail(child, error))
    child.on("exit", (code, signal) => {
      lines.close(); errors.close()
      this.fail(child, new Error(`ACP server exited (${signal ?? code ?? "unknown"})`))
    })
    this.startup = this.requestRaw<InitializeResult>("initialize", {
      protocolVersion: 1,
      clientInfo: { name: "opencode-agy", version: "0.1.0" },
      clientCapabilities: { fs: { readTextFile: false, writeTextFile: false }, terminal: false },
    }, { timeoutMs: 30_000 }).then((result) => {
      if (result.protocolVersion !== 1) throw new Error(`Unsupported ACP version ${result.protocolVersion}`)
      if (this.active === 0) this.armIdle()
      return result
    }).catch((error) => { this.fail(child, error); child.kill(); throw error })
    return this.startup
  }
  async request<T = ObjectValue>(method: string, params: unknown, options: { signal?: AbortSignal; timeoutMs?: number } = {}): Promise<T> {
    await this.initialize()
    return this.requestRaw<T>(method, params, options)
  }
  notify(method: string, params: unknown) { this.write({ jsonrpc: "2.0", method, params }) }
  private write(message: unknown) {
    if (!this.child || this.child.stdin.destroyed) throw new Error("ACP server is not running")
    this.child.stdin.write(JSON.stringify(message) + "\n")
  }
  private requestRaw<T>(method: string, params: unknown, options: { signal?: AbortSignal; timeoutMs?: number }): Promise<T> {
    if (options.signal?.aborted) return Promise.reject(options.signal.reason ?? new Error("Aborted"))
    const id = ++this.sequence
    return new Promise<T>((resolve, reject) => {
      const abort = () => {
        this.calls.delete(id); cleanup(); reject(options.signal?.reason ?? new Error("Aborted"))
      }
      const timer = options.timeoutMs ? setTimeout(() => {
        this.calls.delete(id); cleanup(); reject(new Error(`ACP ${method} timed out`))
      }, options.timeoutMs) : undefined
      const cleanup = () => { clearTimeout(timer); options.signal?.removeEventListener("abort", abort) }
      this.calls.set(id, { resolve: (value) => resolve(value as T), reject, cleanup })
      options.signal?.addEventListener("abort", abort, { once: true })
      try { this.write({ jsonrpc: "2.0", id, method, params }) }
      catch (error) { this.calls.delete(id); cleanup(); reject(error) }
    })
  }
  private async receive(message: { id?: number | string; method?: string; params?: ObjectValue; result?: unknown; error?: { code: number; message: string; data?: unknown } }) {
    if (!message.method) {
      if (typeof message.id !== "number") return
      const call = this.calls.get(message.id)
      if (!call) return
      this.calls.delete(message.id); call.cleanup()
      if (message.error) call.reject(new RpcError(message.error.code, message.error.message, message.error.data))
      else call.resolve(message.result)
      return
    }
    if (message.id === undefined) {
      for (const listener of this.listeners) listener(message.method, message.params ?? {})
      return
    }
    let result: unknown
    let error: { code: number; message: string } | undefined
    if (message.method === "session/request_permission") {
      const request = message.params as unknown as PermissionRequest
      let kind = "reject_once"
      try { kind = await this.options.permission?.(request) ?? "reject_once" } catch { /* fail closed */ }
      const choice = request.options.find((option) => option.kind === kind)
        ?? request.options.find((option) => option.kind.startsWith("reject"))
      result = { outcome: choice ? { outcome: "selected", optionId: choice.optionId } : { outcome: "cancelled" } }
    } else error = { code: -32601, message: `Client method not supported: ${message.method}` }
    this.write({ jsonrpc: "2.0", id: message.id, ...(error ? { error } : { result }) })
  }
  private fail(child: ChildProcessWithoutNullStreams, error: Error) {
    if (this.child !== child) return
    this.child = undefined; this.startup = undefined
    clearTimeout(this.idle)
    for (const call of this.calls.values()) { call.cleanup(); call.reject(error) }
    this.calls.clear()
    for (const listener of this.exits) listener(error)
  }
  stop() {
    clearTimeout(this.idle); clearTimeout(this.handover)
    const child = this.child
    if (!child) return
    this.fail(child, new Error("ACP server stopped"))
    child.stdin.end(); child.kill("SIGTERM")
    const kill = setTimeout(() => { if (child.exitCode === null) child.kill("SIGKILL") }, 2_000)
    kill.unref(); child.once("exit", () => clearTimeout(kill))
  }
}
