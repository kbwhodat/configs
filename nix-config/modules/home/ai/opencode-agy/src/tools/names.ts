import { createHash } from "node:crypto"
import type { LanguageModelV3FunctionTool } from "@ai-sdk/provider"
export * as ToolNames from "./names.js"
export const PREFIX = "mcp__opencode__"
export function short(name: string) {
  const limit = 64 - PREFIX.length
  if (name.length <= limit && /^[a-zA-Z0-9_-]+$/.test(name)) return name
  return name.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, limit - 11) + "_" + createHash("sha256").update(name).digest("hex").slice(0, 10)
}
export function original(name: string, tools: readonly LanguageModelV3FunctionTool[]) {
  return tools.find((tool) => short(tool.name) === name || PREFIX + short(tool.name) === name)?.name
}
export function description(tool: LanguageModelV3FunctionTool) {
  const text = tool.description ?? ""
  const agents = tool.name === "subagent" ? text.indexOf("Available subagents:") : -1
  return (agents < 0 ? text : text.slice(agents) + "\n\n" + text.slice(0, agents)).slice(0, 2048)
}
