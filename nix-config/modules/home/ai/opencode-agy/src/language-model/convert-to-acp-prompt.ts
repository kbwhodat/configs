import { randomUUID } from "node:crypto"
import type { LanguageModelV3FilePart, LanguageModelV3Prompt } from "@ai-sdk/provider"
import type { ContentBlock } from "../acp/session.js"
export * as ConvertToAcpPrompt from "./convert-to-acp-prompt.js"
export type { ContentBlock }
export function content(prompt: LanguageModelV3Prompt, capabilities: { image?: boolean; embeddedContext?: boolean } = {}): ContentBlock[] {
  const blocks: ContentBlock[] = []
  const history = prompt.some((message) => message.role === "assistant" || message.role === "tool")
  for (const message of prompt) {
    if (message.role === "system") continue
    if (history) blocks.push({ type: "text", text: `<${message.role}>` })
    for (const part of message.content) {
      if (part.type === "text") blocks.push({ type: "text", text: part.text })
      else if (part.type === "file") blocks.push(file(part, capabilities))
      else if (part.type === "tool-call") blocks.push({ type: "text", text: `<tool-call>\n${JSON.stringify({ id: part.toolCallId, name: part.toolName, input: part.input })}\n</tool-call>` })
      else if (part.type === "tool-result") blocks.push({ type: "text", text: `<tool-result>\n${JSON.stringify({ id: part.toolCallId, name: part.toolName, output: part.output })}\n</tool-result>` })
    }
    if (history) blocks.push({ type: "text", text: `</${message.role}>` })
  }
  return blocks
}
function file(part: LanguageModelV3FilePart, capabilities: { image?: boolean; embeddedContext?: boolean }): ContentBlock {
  // Fetching arbitrary URLs here would introduce SSRF and authentication ambiguity.
  if (part.data instanceof URL) {
    if (part.data.protocol !== "data:") throw new Error("Antigravity attachments require inline data, not remote URLs")
    const match = /^data:([^;,]+)?(;base64)?,([\s\S]*)$/.exec(part.data.href)
    if (!match) throw new Error("Invalid attachment data URL")
    const data = match[2] ? match[3]! : Buffer.from(decodeURIComponent(match[3]!)).toString("base64")
    return file({ ...part, data }, capabilities)
  }
  const data = typeof part.data === "string" ? part.data : Buffer.from(part.data).toString("base64")
  if (part.mediaType.startsWith("image/")) {
    if (!capabilities.image) throw new Error("The ACP server does not support images")
    return { type: "image", data, mimeType: part.mediaType }
  }
  if (part.mediaType === "application/pdf") {
    if (!capabilities.embeddedContext) throw new Error("The ACP server does not support embedded PDF context")
    return { type: "resource", resource: { uri: `opencode://attachment/${randomUUID()}`, mimeType: part.mediaType, blob: data } }
  }
  throw new Error(`Antigravity does not support ${part.mediaType} attachments`)
}
