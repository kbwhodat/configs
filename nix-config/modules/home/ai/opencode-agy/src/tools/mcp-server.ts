import { createServer, type Server, type ServerResponse } from "node:http"
import { randomUUID } from "node:crypto"
import type { LanguageModelV3FunctionTool } from "@ai-sdk/provider"
import { ToolNames } from "./names.js"
import type { PendingTools } from "./pending.js"

export interface Binding { tools: readonly LanguageModelV3FunctionTool[]; pending: PendingTools }
export interface McpServerConfig {
  type: "http"; name: "opencode"; url: string; headers: Array<{ name: string; value: string }>
}
/** JSON-only Streamable HTTP. An unguessable path token prevents other local/browser clients executing tools. */
export class ToolServer {
  private server?: Server
  private starting?: Promise<void>
  private port = 0
  private readonly token = randomUUID()
  private bindings = new Map<string, Binding>()
  async start() {
    this.starting ??= new Promise<void>((resolve, reject) => {
      const server = createServer((request, response) => { void this.handle(request, response).catch(() => {
        if (!response.headersSent) response.writeHead(500)
        response.end()
      }) })
      this.server = server
      server.on("error", reject)
      server.listen(0, "127.0.0.1", () => {
        const address = server.address()
        if (!address || typeof address === "string") { reject(new Error("MCP listen failed")); return }
        this.port = address.port; resolve()
      })
    })
    await this.starting
  }
  async bind(sessionID: string, binding: Binding): Promise<McpServerConfig> {
    await this.start()
    this.bindings.set(sessionID, binding)
    return { type: "http", name: "opencode", url: `http://127.0.0.1:${this.port}/s/${encodeURIComponent(sessionID)}?key=${this.token}`, headers: [] }
  }
  update(sessionID: string, tools: readonly LanguageModelV3FunctionTool[]) {
    const binding = this.bindings.get(sessionID)
    if (!binding) throw new Error(`No MCP binding for ${sessionID}`)
    binding.tools = tools
  }
  unbind(sessionID: string) {
    this.bindings.get(sessionID)?.pending.clear()
    this.bindings.delete(sessionID)
  }
  private async handle(request: import("node:http").IncomingMessage, response: ServerResponse) {
    const url = new URL(request.url ?? "/", "http://127.0.0.1")
    if (request.headers.origin || request.headers.host !== `127.0.0.1:${this.port}` || url.searchParams.get("key") !== this.token) {
      response.writeHead(403).end(); return
    }
    const match = /^\/s\/([^/]+)$/.exec(url.pathname)
    const binding = match ? this.bindings.get(decodeURIComponent(match[1]!)) : undefined
    if (!binding) { response.writeHead(404).end(); return }
    if (request.method !== "POST") { response.writeHead(405, { Allow: "POST" }).end(); return }
    if (!request.headers["content-type"]?.includes("application/json")) { response.writeHead(415).end(); return }
    let size = 0
    const chunks: Buffer[] = []
    for await (const chunk of request) {
      size += chunk.length
      if (size > 4 * 1024 * 1024) { response.writeHead(413).end(); return }
      chunks.push(Buffer.from(chunk))
    }
    let message: { jsonrpc: string; id?: string | number; method: string; params?: Record<string, unknown> }
    const send = (body: unknown) => response.writeHead(200, { "Content-Type": "application/json" }).end(JSON.stringify(body))
    try { message = JSON.parse(Buffer.concat(chunks).toString("utf8")) }
    catch { send({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "Parse error" } }); return }
    if (!message || message.jsonrpc !== "2.0" || typeof message.method !== "string") {
      send({ jsonrpc: "2.0", id: null, error: { code: -32600, message: "Invalid Request" } }); return
    }
    if (message.id === undefined) { response.writeHead(202).end(); return }
    let result: unknown
    let error: { code: number; message: string } | undefined
    switch (message.method) {
      case "initialize": result = { protocolVersion: "2025-06-18", serverInfo: { name: "opencode", version: "0.1.0" }, capabilities: { tools: { listChanged: true } } }; break
      case "ping": result = {}; break
      case "tools/list": result = { tools: binding.tools.map((tool) => ({ name: ToolNames.short(tool.name), description: ToolNames.description(tool), inputSchema: tool.inputSchema })) }; break
      case "tools/call": {
        const name = typeof message.params?.name === "string" ? ToolNames.original(message.params.name, binding.tools) : undefined
        if (!name) { error = { code: -32602, message: "Unknown tool" }; break }
        const args = message.params?.arguments ?? {}
        if (!args || typeof args !== "object" || Array.isArray(args)) { error = { code: -32602, message: "Tool arguments must be an object" }; break }
        result = await binding.pending.call(name, args).result
        break
      }
      default: error = { code: -32601, message: "Method not found" }
    }
    if (!response.destroyed) send({ jsonrpc: "2.0", id: message.id, ...(error ? { error } : { result }) })
  }
  async close() {
    for (const id of this.bindings.keys()) this.unbind(id)
    const server = this.server
    this.server = undefined; this.starting = undefined
    if (!server) return
    server.closeIdleConnections()
    await new Promise<void>((resolve) => { server.close(() => resolve()); server.closeAllConnections() })
  }
}
