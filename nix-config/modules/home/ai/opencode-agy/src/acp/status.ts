import { accessSync, constants } from "node:fs"
import { serverPath, type AcpProcess } from "./process.js"
import type { SessionInfo } from "./session.js"
import { catalog, type CatalogModel } from "../provider.js"
import { message } from "./errors.js"

export type State = { type: "checking" } | { type: "missing" } | { type: "failed"; message: string }
  | { type: "ready"; tier: NonNullable<NonNullable<SessionInfo["_meta"]>["antigravity"]>["tier"]; models: CatalogModel[]; protocolVersion: number }
type Process = Pick<AcpProcess, "options" | "initialize" | "request" | "retain">
export class Status {
  state: State = { type: "checking" }
  private lock: Promise<void> = Promise.resolve()
  private listeners = new Set<(state: State) => Promise<void>>()
  constructor(readonly process: Process) {}
  subscribe(listener: (state: State) => Promise<void>) {
    this.listeners.add(listener)
    return () => { this.listeners.delete(listener) }
  }
  async report(next: State) {
    this.state = next
    for (const listener of this.listeners) await listener(next)
  }
  refresh(): Promise<void> {
    const task = this.lock.then(async () => {
      await this.report({ type: "checking" })
      try { accessSync(serverPath(this.process.options.serverPath), constants.X_OK) }
      catch { await this.report({ type: "missing" }); return }
      const release = this.process.retain()
      let next: State
      try {
        const init = await this.process.initialize()
        const info = await this.process.request<SessionInfo>("session/new", {
          cwd: this.process.options.directory, mcpServers: [], _meta: { antigravity: { enabledTools: [] } },
        }, { timeoutMs: 30_000 })
        try {
          next = { type: "ready", tier: info._meta?.antigravity?.tier, models: catalog(info).models, protocolVersion: init.protocolVersion }
        } finally { await this.process.request("session/close", { sessionId: info.sessionId }, { timeoutMs: 10_000 }) }
      } catch (error) { next = { type: "failed", message: message(error) } }
      finally { release() }
      await this.report(next)
    })
    this.lock = task.catch(() => {})
    return task
  }
}
