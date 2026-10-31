import { randomUUID } from "node:crypto"
import type { CallToolResult } from "./result.js"
export interface Call { id: string; name: string; input: unknown }
export class PendingTools {
  private calls = new Map<string, { call: Call; resolve: (result: CallToolResult) => void; emitted: boolean }>()
  private listeners = new Set<() => void>()
  onCall(listener: () => void) { this.listeners.add(listener); return () => { this.listeners.delete(listener) } }
  call(name: string, input: unknown): { call: Call; result: Promise<CallToolResult> } {
    const call = { id: `agy_${randomUUID()}`, name, input }
    const result = new Promise<CallToolResult>((resolve) => this.calls.set(call.id, { call, resolve, emitted: false }))
    for (const listener of this.listeners) listener()
    return { call, result }
  }
  take(): Call | undefined {
    for (const item of this.calls.values()) {
      if (item.emitted) continue
      item.emitted = true
      return item.call
    }
  }
  get waiting(): string[] { return [...this.calls].filter(([, item]) => item.emitted).map(([id]) => id) }
  get size() { return this.calls.size }
  resolve(id: string, result: CallToolResult) {
    const item = this.calls.get(id)
    if (!item || !item.emitted) throw new Error(`No waiting Antigravity tool call ${id}`)
    this.calls.delete(id); item.resolve(result)
  }
  clear(reason = "Cancelled by user.") {
    const calls = [...this.calls.values()]
    this.calls.clear()
    for (const item of calls) item.resolve({ isError: true, content: [{ type: "text", text: reason }] })
  }
}
export type Interface = PendingTools
export const make = () => new PendingTools()
