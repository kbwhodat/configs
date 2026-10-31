import { describe, expect, test } from "bun:test"
import type { LanguageModelV3Prompt } from "@ai-sdk/provider"
import type { Plugin } from "@opencode/plugin"
import { AcpProcess, type InitializeResult, type ObjectValue } from "../src/acp/process.js"
import { AcpSession, selectModel, sessionParams, type SessionEvent, type SessionInfo } from "../src/acp/session.js"
import { Sessions } from "../src/acp/sessions.js"
import { ToolServer } from "../src/tools/mcp-server.js"
import { groups } from "../src/sync/fingerprint.js"
import { decide } from "../src/sync/decide.js"
import { catalog } from "../src/provider.js"
import type { Request } from "../src/language-model/agy-language-model.js"

class FakeProcess extends AcpProcess {
  notifications = new Set<(method: string, params: ObjectValue) => void>()
  requests: Array<{ method: string; params: any }> = []
  count = 0
  failLoad = false
  failFork = false
  emptyFork = false
  configs = new Map<string, SessionInfo["configOptions"]>()
  bridge = false
  urls = new Map<string, string>()
  generation = 1
  constructor() { super({ directory: process.cwd() }) }
  override async initialize(): Promise<InitializeResult> {
    return { protocolVersion: 1, authMethods: [], agentCapabilities: { loadSession: true, promptCapabilities: { image: true, embeddedContext: true } } }
  }
  override onNotification(listener: (method: string, params: ObjectValue) => void) { this.notifications.add(listener); return () => { this.notifications.delete(listener) } }
  override onExit() { return () => {} }
  override retain() { return () => {} }
  override stop() {}
  override notify() {}
  override async request<T = ObjectValue>(method: string, params: any): Promise<T> {
    this.requests.push({ method, params })
    if (method === "session/load" && this.failLoad) throw new Error("not found")
    if (method === "session/fork" && this.failFork) throw new Error("fork unavailable")
    if (method === "session/fork" && this.emptyFork) return {} as T
    if (method === "session/new" || method === "session/load" || method === "session/fork") {
      const sessionId = method === "session/load" ? params.sessionId : `acp-${++this.count}`
      if (params.mcpServers[0]) this.urls.set(sessionId, params.mcpServers[0].url)
      const configOptions = structuredClone((method === "session/fork" ? this.configs.get(params.sessionId) : undefined) ?? [{ id: "model", currentValue: "gemini-4-argon-medium", options: ["low", "medium", "high"].map((effort) => ({ value: `gemini-4-argon-${effort}`, name: effort })) }])
      this.configs.set(sessionId, configOptions as SessionInfo["configOptions"])
      return { sessionId, configOptions } as T
    }
    if (method === "session/prompt") {
      if (this.bridge) {
        const result = await fetch(this.urls.get(params.sessionId)!, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "read", arguments: { path: "example" } } }) }).then((response) => response.json())
        expect(result.result.content[0].text).toBe("contents")
      }
      for (const listener of this.notifications) listener("session/update", { sessionId: params.sessionId, update: { sessionUpdate: "agent_message_chunk", content: { type: "text", text: "reply" } } })
      return { stopReason: "end_turn" } as T
    }
    if (method === "session/set_config_option") {
      const option = this.configs.get(params.sessionId)?.find((option) => option.id === params.configId)
      if (option) option.currentValue = params.value
      return { configOptions: [{ id: params.configId, currentValue: params.value }] } as T
    }
    return {} as T
  }
}
function setup(process = new FakeProcess(), data = new Map<string, unknown>()) {
  const tools = new ToolServer()
  const storage = { get: async (key: string) => data.get(key), set: async (key: string, value: unknown) => { data.set(key, value) } } as Plugin.Context["storage"]
  const sessions = new Sessions({ process, tools, storage, directory: globalThis.process.cwd(), catalog: async () => {} })
  return { sessions, process, data }
}
const user = (text: string): LanguageModelV3Prompt => [{ role: "user", content: [{ type: "text", text }] }]
const request = (prompt: LanguageModelV3Prompt, emit: (event: SessionEvent) => void = () => {}): Request => ({ sessionID: "oc-1", kind: "primary", model: "argon", effort: "medium", system: "system", prompt, tools: [], settings: {}, emit })
const signal = () => new AbortController().signal

describe("sync", () => {
  test("normalizes split text and reasoning, and detects edits", () => {
    const prompt = user("hi")
    const record = { acpSessionID: "a", history: groups(prompt).map(({ hash }) => ({ hash })), interrupted: false }
    expect(decide([...prompt, { role: "assistant", content: [{ type: "text", text: "yes" }] }], record)).toEqual({ kind: "continue", start: 1 })
    expect(decide(user("edited"), record).kind).toBe("changed")
    expect(decide(prompt, { ...record, interrupted: true }).kind).toBe("changed")
    expect(groups([{ role: "assistant", content: [{ type: "text", text: "ab" }] }])[0]?.hash).toBe(groups([{ role: "assistant", content: [{ type: "text", text: "a" }, { type: "reasoning", text: "hidden" }, { type: "text", text: "b" }] }])[0]?.hash)
  })
  test("maps both real catalog layouts centrally", () => {
    const info: SessionInfo = { sessionId: "a", configOptions: [{ id: "model", type: "select", name: "Model", currentValue: "gemini-4-argon", options: [{ value: "gemini-4-argon", name: "Argon" }] }, { id: "thinking_level", type: "select", name: "Thinking", currentValue: "medium" }] }
    expect(selectModel("argon", "high", info)).toEqual([["model", "gemini-4-argon"], ["thinking_level", "high"]])
    expect(catalog(info).models).toEqual([{ id: "gemini-4-argon", name: "Argon" }])
    expect(sessionParams({ directory: "/a", system: "rules" })._meta.antigravity.enabledTools).toEqual([])
  })
})
describe("registry", () => {
  const settled = (): LanguageModelV3Prompt => [...user("hi"), { role: "assistant", content: [{ type: "text", text: "reply" }] }]
  for (const kind of ["generate", "summary", "compaction"] as const) {
    test(`${kind} forks a live source, sends only instruction and closes the copy`, async () => {
      const { sessions, process, data } = setup()
      try {
        await sessions.run({ ...request(user("hi")), effort: "high" }, signal())
        const before = process.requests.length
        await sessions.run({ ...request([...settled(), ...user("instruction")]), sessionID: undefined, sourceID: "oc-1", kind, model: "gemini-3.8-flash", effort: "low" }, signal())
        const calls = process.requests.slice(before)
        expect(calls.find((call) => call.method === "session/fork")?.params).toEqual({ sessionId: "acp-1", cwd: globalThis.process.cwd(), mcpServers: [] })
        expect(calls.find((call) => call.method === "session/prompt")?.params.prompt).toEqual([{ type: "text", text: "instruction" }])
        expect(calls.filter((call) => call.method === "session/set_config_option")).toHaveLength(0)
        expect(process.configs.get("acp-2")?.find((option) => option.id === "model")?.currentValue).toBe("gemini-4-argon-high")
        expect(calls.some((call) => call.method === "session/close" && call.params.sessionId === "acp-2")).toBe(true)
        expect(calls.some((call) => call.method === "session/close" && call.params.sessionId === "acp-1")).toBe(kind === "compaction")
        expect(data.size).toBe(1)
      } finally { await sessions.close() }
    })
  }
  test("forks a stored source into a primary session at the full matched boundary", async () => {
    const data = new Map<string, unknown>([["sessions/source", { acpSessionID: "stored", history: groups(settled()).map(({ hash }) => ({ hash })), interrupted: false }]])
    const { sessions, process } = setup(new FakeProcess(), data)
    try {
      await sessions.run({ ...request([...settled(), ...user("next")]), sourceID: "source" }, signal())
      expect(process.requests.some((call) => call.method === "session/fork" && call.params.sessionId === "stored")).toBe(true)
      expect(process.requests.find((call) => call.method === "session/prompt")?.params.prompt).toEqual([{ type: "text", text: "next" }])
      expect((data.get("sessions/oc-1") as any).acpSessionID).toBe("acp-1")
      expect((data.get("sessions/oc-1") as any).history.slice(0, 2)).toEqual(groups(settled()).map(({ hash }) => ({ hash })))
    } finally { await sessions.close() }
  })
  test("primary live forks bind their own MCP endpoint and continue without reforking", async () => {
    const { sessions, process, data } = setup()
    try {
      await sessions.run(request(user("hi")), signal())
      const child = { ...request([...settled(), ...user("next")]), sessionID: "child", sourceID: "oc-1" }
      await sessions.run(child, signal())
      const fork = process.requests.find((call) => call.method === "session/fork")!
      expect(fork.params.mcpServers[0].url).toContain("/s/child?")
      expect(fork.params.mcpServers[0].url).not.toBe(process.urls.get("acp-1"))
      expect(sessions.owner("acp-2")).toBe("child")
      await sessions.run({ ...child, prompt: [...child.prompt, { role: "assistant", content: [{ type: "text", text: "reply" }] }, ...user("again")] }, signal())
      expect(process.requests.filter((call) => call.method === "session/fork")).toHaveLength(1)
      expect(process.requests.filter((call) => call.method === "session/prompt").at(-1)?.params.prompt).toEqual([{ type: "text", text: "again" }])
      expect((data.get("sessions/child") as any).acpSessionID).toBe("acp-2")
      // Even with a valid lineage, edits to an existing child's history rebuild, never fork.
      await sessions.run({ ...child, prompt: [...settled(), ...user("edited")] }, signal())
      expect(process.requests.filter((call) => call.method === "session/fork")).toHaveLength(1)
      expect(process.count).toBe(3)
    } finally { await sessions.close() }
  })
  test("failed primary forks rebuild from the full transcript", async () => {
    const { sessions, process } = setup()
    try {
      await sessions.run(request(user("hi")), signal())
      process.failFork = true
      await sessions.run({ ...request([...settled(), ...user("next")]), sessionID: "child", sourceID: "oc-1" }, signal())
      expect(process.requests.filter((call) => call.method === "session/prompt")[1]?.params.prompt.some((block: any) => block.text === "hi")).toBe(true)
      expect(process.count).toBe(2)
    } finally { await sessions.close() }
  })
  test("fork preserves model and thinking_level, changing only a different requested option", async () => {
    const process = new FakeProcess()
    const options = { directory: globalThis.process.cwd(), system: "" }
    const source = await AcpSession.open(process, options)
    source.info.configOptions = [
      { id: "model", name: "Model", type: "select", currentValue: "gemini-4-argon", options: [{ value: "gemini-4-argon", name: "Argon" }] },
      { id: "thinking_level", name: "Thinking", type: "select", currentValue: "high" },
    ]
    process.configs.set(source.id, source.info.configOptions)
    const fork = await AcpSession.fork(process, source.id, options)
    try {
      await fork.configure("argon", "high")
      expect(process.requests.filter((call) => call.method === "session/set_config_option")).toHaveLength(0)
      await fork.configure("argon", "low")
      expect(process.requests.filter((call) => call.method === "session/set_config_option").map((call) => call.params)).toEqual([{ sessionId: fork.id, configId: "thinking_level", value: "low" }])
      expect(source.info.configOptions[1]?.currentValue).toBe("high")
    } finally { await fork.close(); await source.close() }
  })
  for (const prompt of [user("edited"), user("hi")]) {
    test("primary mismatched or truncated source prefixes rebuild without forking", async () => {
      const { sessions, process } = setup()
      try {
        await sessions.run(request(user("hi")), signal())
        await sessions.run({ ...request(prompt), sessionID: "child", sourceID: "oc-1" }, signal())
        expect(process.requests.some((call) => call.method === "session/fork")).toBe(false)
        expect(process.count).toBe(2)
      } finally { await sessions.close() }
    })
  }
  for (const failure of ["failFork", "emptyFork"] as const) {
    test(`${failure}: side forks fall back to transcript and compaction still stops source`, async () => {
      const { sessions, process } = setup()
      try {
        await sessions.run(request(user("hi")), signal())
        process[failure] = true
        await sessions.run({ ...request([...settled(), ...user("instruction")]), sessionID: undefined, sourceID: "oc-1", kind: "compaction" }, signal())
        const prompts = process.requests.filter((call) => call.method === "session/prompt")
        expect(prompts[1]?.params.prompt.some((block: any) => block.text === "hi")).toBe(true)
        expect(process.requests.some((call) => call.method === "session/close" && call.params.sessionId === "acp-1")).toBe(true)
        expect(process.count).toBe(2)
      } finally { await sessions.close() }
    })
  }
  test("title never forks and instruction-only generate forks a stored source", async () => {
    const { sessions, process, data } = setup()
    data.set("sessions/source", { acpSessionID: "stored", history: groups(settled()).map(({ hash }) => ({ hash })), interrupted: false })
    try {
      await sessions.run({ ...request(user("title")), sessionID: undefined, sourceID: "source", kind: "title" }, signal())
      expect(process.requests.some((call) => call.method === "session/fork")).toBe(false)
      await sessions.run({ ...request(user("instruction")), sessionID: undefined, sourceID: "source", kind: "generate" }, signal())
      expect(process.requests.some((call) => call.method === "session/fork")).toBe(true)
      expect(process.requests.filter((call) => call.method === "session/prompt")[1]?.params.prompt).toEqual([{ type: "text", text: "instruction" }])
    } finally { await sessions.close() }
  })
  test("persists replies, sends only new input, rebuilds changed histories", async () => {
    const { sessions, process, data } = setup()
    try {
      const prompt = user("hi")
      await sessions.run(request(prompt), signal())
      expect(data.has("sessions/oc-1")).toBe(true)
      const next: LanguageModelV3Prompt = [...prompt, { role: "assistant", content: [{ type: "text", text: "reply" }] }, ...user("next")]
      await sessions.run(request(next), signal())
      expect(process.count).toBe(1)
      expect(process.requests.filter((item) => item.method === "session/prompt")[1]?.params.prompt).toEqual([{ type: "text", text: "next" }])
      expect(process.requests.filter((item) => item.method === "session/set_config_option")).toHaveLength(0)
      await sessions.run(request(user("changed")), signal())
      expect(process.count).toBe(2)
    } finally { await sessions.close() }
  })
  test("parks MCP and resumes the same prompt after the OpenCode result", async () => {
    const { sessions, process } = setup()
    process.bridge = true
    try {
      const events: SessionEvent[] = []
      const prompt = user("read")
      const first = request(prompt, (event) => events.push(event))
      first.tools = [{ type: "function", name: "read", inputSchema: { type: "object" } }]
      await sessions.run(first, signal())
      const call = events.find((event) => event.type === "tool")
      expect(call?.type).toBe("tool")
      if (call?.type !== "tool") throw new Error("missing call")
      const next: LanguageModelV3Prompt = [...prompt, { role: "assistant", content: [{ type: "tool-call", toolCallId: call.call.id, toolName: "read", input: call.call.input }] }, { role: "tool", content: [{ type: "tool-result", toolCallId: call.call.id, toolName: "read", output: { type: "text", value: "contents" } }] }]
      await sessions.run({ ...first, prompt: next }, signal())
      expect(process.requests.filter((item) => item.method === "session/prompt")).toHaveLength(1)
      expect(events.at(-1)?.type).toBe("result")
    } finally { await sessions.close() }
  })
  test("loads saved sessions after restart, and rebuilds on load error", async () => {
    const data = new Map<string, unknown>()
    const first = setup(new FakeProcess(), data)
    await first.sessions.run(request(user("hi")), signal())
    await first.sessions.close()
    const second = setup(new FakeProcess(), data)
    const next: LanguageModelV3Prompt = [...user("hi"), { role: "assistant", content: [{ type: "text", text: "reply" }] }, ...user("next")]
    try {
      await second.sessions.run(request(next), signal())
      expect(second.process.requests.some((item) => item.method === "session/load")).toBe(true)
    } finally { await second.sessions.close() }
    const third = setup(new FakeProcess(), data)
    third.process.failLoad = true
    try {
      await third.sessions.run(request([...next, { role: "assistant", content: [{ type: "text", text: "reply" }] }, ...user("again")]), signal())
      expect(third.process.requests.some((item) => item.method === "session/load")).toBe(true)
      expect(third.process.requests.some((item) => item.method === "session/new")).toBe(true)
    } finally { await third.sessions.close() }
  })
  test("utility sessions are isolated and tool-free", async () => {
    const { sessions, process, data } = setup()
    try {
      await sessions.run({ ...request(user("title")), sessionID: undefined, kind: "title" }, signal())
      await sessions.run({ ...request(user("summary")), sessionID: undefined, kind: "summary" }, signal())
      expect(process.count).toBe(2)
      expect(data.size).toBe(0)
      expect(process.requests.filter((item) => item.method === "session/new").every((item) => item.params.mcpServers.length === 0)).toBe(true)
    } finally { await sessions.close() }
  })
  test("configure does not resend unchanged options", async () => {
    const process = new FakeProcess()
    const session = await AcpSession.open(process, { directory: globalThis.process.cwd(), system: "" })
    try {
      await session.configure("argon", "high")
      await session.configure("argon", "high")
      expect(process.requests.filter((item) => item.method === "session/set_config_option")).toHaveLength(1)
    } finally { await session.close() }
  })
})
