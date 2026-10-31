import { expect, test } from "bun:test"
import { AcpProcess, RpcError, type InitializeResult, type ObjectValue } from "../src/acp/process.js"
import { Status, type State } from "../src/acp/status.js"
import { AUTH_HELP, MISSING_HELP } from "../src/acp/errors.js"
import { readable } from "../src/language-model/agy-error.js"
import { problem } from "../src/integration.js"
import type { SessionInfo } from "../src/acp/session.js"
import type { Plugin } from "@opencode/plugin"
import { register } from "../src/provider.js"

class FakeProcess extends AcpProcess {
  requests: Array<{ method: string; params: unknown }> = []
  initialized?: () => void
  error?: Error
  gate?: Promise<void>
  retained = 0
  info: SessionInfo = {
    sessionId: "probe", _meta: { antigravity: { tier: { id: "pro", name: "Pro", upgradeUri: "https://example.com" } } },
    configOptions: [{ id: "model", name: "Model", type: "select", currentValue: "flash", options: [{ value: "flash", name: "Flash" }] }],
  }
  constructor() { super({ directory: process.cwd(), serverPath: process.execPath }) }
  override retain() { this.retained++; return () => { this.retained-- } }
  override async initialize(): Promise<InitializeResult> {
    this.requests.push({ method: "initialize", params: {} })
    this.initialized?.()
    await this.gate
    return { protocolVersion: 1, authMethods: [], agentCapabilities: {} }
  }
  override async request<T = ObjectValue>(method: string, params: unknown): Promise<T> {
    this.requests.push({ method, params })
    if (this.error) throw this.error
    return (method === "session/new" ? this.info : {}) as T
  }
}

test("checking → missing → auth failure → ready; probe is tool-free, closed, and never authenticates", async () => {
  const process = new FakeProcess()
  const status = new Status(process)
  const states: State[] = []
  status.subscribe(async (state) => { states.push(state) })
  expect(status.state).toEqual({ type: "checking" })
  const executable = process.options.serverPath
  process.options.serverPath = "/nonexistent/agy-status-test"
  await status.refresh()
  expect(status.state).toEqual({ type: "missing" })
  expect(problem(status.state)?.message).toBe(MISSING_HELP)
  expect(process.requests).toHaveLength(0)
  process.options.serverPath = executable
  process.error = new RpcError(-32000, "auth_required")
  await status.refresh()
  expect(status.state).toEqual({ type: "failed", message: AUTH_HELP })
  expect(readable(process.error).message).toBe(AUTH_HELP)
  expect(readable(Object.assign(new Error("raw failure"), { code: -32000 })).message).toBe(AUTH_HELP)
  expect(problem(status.state)?.message).toBe(AUTH_HELP)
  process.error = undefined
  await status.refresh()
  expect(status.state).toEqual({ type: "ready", tier: process.info._meta?.antigravity?.tier, models: [{ id: "flash", name: "Flash" }], protocolVersion: 1 })
  expect(problem(status.state)).toBeUndefined()
  expect(process.requests.at(-2)).toEqual({ method: "session/new", params: { cwd: process.options.directory, mcpServers: [], _meta: { antigravity: { enabledTools: [] } } } })
  expect(process.requests.at(-1)).toEqual({ method: "session/close", params: { sessionId: "probe" } })
  expect(process.requests.some(({ method }) => method === "authenticate")).toBe(false)
  expect(process.retained).toBe(0)
  expect(states.map(({ type }) => type)).toEqual(["checking", "missing", "checking", "failed", "checking", "ready"])
})

test("refresh queues reconnect behind startup and report accepts a chat's own result", async () => {
  const process = new FakeProcess()
  const status = new Status(process)
  let release!: () => void
  process.gate = new Promise<void>((resolve) => { release = resolve })
  const initialized = new Promise<void>((resolve) => { process.initialized = resolve })
  const first = status.refresh()
  const second = status.refresh()
  await initialized
  expect(process.requests.map(({ method }) => method)).toEqual(["initialize"])
  release()
  await Promise.all([first, second])
  expect(process.requests.map(({ method }) => method)).toEqual(["initialize", "session/new", "session/close", "initialize", "session/new", "session/close"])
  await status.report({ type: "failed", message: "transport failed" })
  expect(status.state).toEqual({ type: "failed", message: "transport failed" })
  await status.report({ type: "ready", tier: undefined, models: [], protocolVersion: 1 })
  expect(status.state.type).toBe("ready")
})

test("ready catalog persists and reloads only on change; Flash exposes effort variants", async () => {
  let reloads = 0
  let writes = 0
  let transform!: Parameters<Plugin.Context["provider"]["transform"]>[0]
  const ctx = {
    storage: { get: async () => undefined, set: async () => { writes++ } },
    provider: { transform: async (fn: typeof transform) => { transform = fn }, reload: async () => { reloads++ } },
  } as unknown as Plugin.Context
  const update = await register(ctx)
  const next = { models: [{ id: "gemini-3.8-flash", name: "Flash" }] }
  await update(next)
  await update(structuredClone(next))
  expect(writes).toBe(1)
  expect(reloads).toBe(1)
  let models: Array<{ id: string; variants: Array<{ id: string }> }> = []
  await transform({ add: (input: { models: typeof models }) => { models = input.models } } as never)
  expect(models.find(({ id }) => id === "flash")?.variants.map(({ id }) => id)).toEqual(["low", "medium", "high"])
})
