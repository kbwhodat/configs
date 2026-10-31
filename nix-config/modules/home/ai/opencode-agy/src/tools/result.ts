import type { LanguageModelV3FilePart, LanguageModelV3Prompt, LanguageModelV3ToolResultOutput } from "@ai-sdk/provider"
export * as ToolResult from "./result.js"
export type McpContent = { type: "text"; text: string } | { type: "image"; data: string; mimeType: string }
  | { type: "resource"; resource: { uri: string; mimeType: string; blob: string } }
export interface CallToolResult { content: McpContent[]; isError?: boolean }
export interface Result { mcp: CallToolResult }
export function convert(output: LanguageModelV3ToolResultOutput, files: readonly LanguageModelV3FilePart[] = [], failed = false): Result {
  const content: McpContent[] = []
  const text = (value: string) => content.push({ type: "text", text: value })
  const file = (data: string | Uint8Array | URL, mimeType: string) => {
    if (data instanceof URL) {
      text(`Attached resource: ${data.href}`)
      return
    }
    const blob = typeof data === "string" ? data : Buffer.from(data).toString("base64")
    if (mimeType.startsWith("image/")) content.push({ type: "image", data: blob, mimeType })
    else content.push({ type: "resource", resource: { uri: `opencode://tool/${content.length}`, mimeType, blob } })
  }
  switch (output.type) {
    case "text": case "error-text": text(output.value); break
    case "json": case "error-json": text(JSON.stringify(output.value)); break
    case "execution-denied": text(output.reason ?? "Tool execution was denied by the user."); break
    case "content":
      for (const part of output.value) {
        if (part.type === "text") text(part.text)
        else if (part.type === "image-data" || part.type === "file-data") file(part.data, part.mediaType)
        else if (part.type === "image-url" || part.type === "file-url") text(`Attached resource: ${part.url}`)
        else throw new Error(`Unsupported Antigravity tool output: ${part.type}`)
      }
  }
  for (const part of files) file(part.data, part.mediaType)
  return { mcp: { content, isError: failed || ["error-text", "error-json", "execution-denied"].includes(output.type) } }
}
/** Collect only the contiguous tool-result prefix; never consume a new user request. */
export function collect(prompt: LanguageModelV3Prompt, start = 0) {
  const results = new Map<string, Result>()
  let end = start
  let aborted = false
  while (end < prompt.length) {
    const message = prompt[end]!
    if (message.role !== "tool") break
    const next = prompt[end + 1]
    const media = next?.role === "user" && next.content[0]?.type === "text" && next.content[0].text === "Attached media from tool result:"
      ? next.content.filter((part): part is LanguageModelV3FilePart => part.type === "file") : []
    const parts = message.content.filter((part) => part.type === "tool-result")
    for (const [index, part] of parts.entries()) {
      const flags = part.providerOptions?.agy
      aborted ||= flags?.toolAborted === true || part.output.type === "execution-denied"
      results.set(part.toolCallId, convert(part.output, index === parts.length - 1 ? media : [], flags?.toolError === true))
    }
    end += media.length ? 2 : 1
  }
  return { results, end, aborted }
}
