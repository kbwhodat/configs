import type { Plugin } from "@opencode/plugin"
export interface Checkpoint { hash: string }
export interface Record { acpSessionID: string; history: Checkpoint[]; interrupted: boolean }
export type Storage = Pick<Plugin.Context["storage"], "get" | "set">
export function make(storage: Storage) {
  return {
    async get(id: string): Promise<Record | undefined> {
      const stored: unknown = await storage.get(`sessions/${id}`)
      const value = stored as { acpSessionID?: unknown; history?: unknown; interrupted?: unknown } | undefined
      if (!value || typeof value !== "object" || Array.isArray(value)) return
      if (typeof value.acpSessionID !== "string" || !Array.isArray(value.history) || typeof value.interrupted !== "boolean") return
      if (!value.history.every((item) => item && typeof item === "object" && !Array.isArray(item) && typeof item.hash === "string")) return
      return value as unknown as Record
    },
    set: (id: string, record: Record) => storage.set(`sessions/${id}`, { ...record, history: record.history.map((item) => ({ ...item })) }),
  }
}
