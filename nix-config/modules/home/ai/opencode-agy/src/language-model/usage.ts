import type { LanguageModelV3Usage } from "@ai-sdk/provider"
import type { ObjectValue } from "../acp/process.js"
export * as AgyUsage from "./usage.js"
const count = (value: unknown): number | undefined => typeof value === "number" && Number.isFinite(value) && value >= 0 ? value : undefined
/** usage_update.used is context occupancy, NOT the turn's billed input/output. */
export function make() {
  let context: number | undefined
  let usage: ObjectValue = {}
  return {
    update(update: ObjectValue) {
      context = count(update.used) ?? context
      if (update.usage && typeof update.usage === "object") usage = { ...usage, ...update.usage }
    },
    result(value?: ObjectValue) { if (value) usage = { ...usage, ...value } },
    snapshot(): LanguageModelV3Usage {
      const input = count(usage.inputTokens) ?? count(usage.input_tokens)
      const read = count(usage.cachedReadTokens) ?? count(usage.cached_read_tokens)
      const write = count(usage.cachedWriteTokens) ?? count(usage.cached_write_tokens)
      const text = count(usage.outputTokens) ?? count(usage.output_tokens)
      const reasoning = count(usage.thoughtTokens) ?? count(usage.thought_tokens)
      return {
        inputTokens: { total: input ?? context, noCache: input === undefined ? undefined : Math.max(0, input - (read ?? 0) - (write ?? 0)), cacheRead: read, cacheWrite: write },
        outputTokens: { total: text === undefined && reasoning === undefined ? undefined : (text ?? 0) + (reasoning ?? 0), text, reasoning },
      }
    },
  }
}
