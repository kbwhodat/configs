import type { LanguageModelV3Prompt } from "@ai-sdk/provider"
import { groups } from "./fingerprint.js"
import type { Record } from "./record.js"
export function decide(prompt: LanguageModelV3Prompt, record?: Record) {
  const saved = record?.history ?? []
  const current = groups(prompt, saved)
  if (!saved.length) return { kind: "fresh", start: 0 } as const
  if (record?.interrupted || saved.some((item, index) => current[index]?.hash !== item.hash)) return { kind: "changed", start: 0 } as const
  return { kind: "continue", start: current[saved.length]?.start ?? prompt.length } as const
}
