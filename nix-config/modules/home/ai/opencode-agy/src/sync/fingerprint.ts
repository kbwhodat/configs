import { createHash } from "node:crypto"
import type { LanguageModelV3Message, LanguageModelV3Prompt } from "@ai-sdk/provider"
export interface Group { hash: string; role: "user" | "assistant" | "tool"; start: number; end: number }
function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`
  if (value && typeof value === "object") {
    const object = value as Record<string, unknown>
    return `{${Object.keys(object).sort().filter((key) => object[key] !== undefined).map((key) => `${JSON.stringify(key)}:${canonical(object[key])}`).join(",")}}`
  }
  return JSON.stringify(value) ?? "null"
}
const hash = (value: unknown) => createHash("sha256").update(canonical(value)).digest("hex")
function visible(message: Exclude<LanguageModelV3Message, { role: "system" }>) {
  const parts: unknown[] = []
  let text = ""
  for (const part of message.content) {
    if (part.type === "reasoning") continue
    if (part.type === "text") { text += part.text; continue }
    if (text) parts.push({ type: "text", text })
    text = ""
    if (part.type === "file") parts.push({ type: part.type, mediaType: part.mediaType, data: part.data instanceof URL ? part.data.href : typeof part.data === "string" ? part.data : Buffer.from(part.data).toString("base64") })
    if (part.type === "tool-call") parts.push({ type: part.type, id: part.toolCallId, name: part.toolName, input: part.input })
    if (part.type === "tool-result") {
      const output = { ...part.output }
      if ("providerOptions" in output) delete output.providerOptions
      if (output.type === "content") output.value = output.value.map(({ providerOptions: _, ...item }) => item)
      parts.push({ type: part.type, id: part.toolCallId, name: part.toolName, output })
    }
  }
  if (text) parts.push({ type: "text", text })
  return parts
}
export function groups(prompt: LanguageModelV3Prompt, prefix: readonly { hash: string }[] = []): Group[] {
  const result: Group[] = []
  let i = 0
  while (i < prompt.length) {
    const message = prompt[i++]!
    const start = i - 1
    if (message.role === "system") continue
    const parts = visible(message)
    if (!parts.length) continue
    const members = [hash(parts)]
    if (message.role === "user") while (i < prompt.length) {
      if (prefix[result.length]?.hash === hash({ role: message.role, members: members.toSorted() })) break
      const next = prompt[i]!
      if (next.role !== "user") break
      members.push(hash(visible(next))); i++
    }
    if (message.role === "user") members.sort()
    if (message.role === "tool") {
      const next = prompt[i]
      if (next?.role === "user" && next.content[0]?.type === "text" && next.content[0].text === "Attached media from tool result:" && next.content.slice(1).every((part) => part.type === "file")) {
        members.push(hash(visible(next))); i++
      }
    }
    result.push({ hash: hash({ role: message.role, members }), role: message.role, start, end: i })
  }
  return result
}
