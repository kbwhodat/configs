import { randomUUID } from "node:crypto"
import type { JSONValue, LanguageModelV3FinishReason, LanguageModelV3FunctionTool, LanguageModelV3StreamPart } from "@ai-sdk/provider"
import type { ObjectValue } from "../acp/process.js"
import type { SessionEvent } from "../acp/session.js"
import { ToolNames } from "../tools/names.js"
import { AgyUsage } from "./usage.js"
export * as ConvertAcpStream from "./convert-acp-stream.js"
export function finishReason(reason: string): LanguageModelV3FinishReason {
  return { unified: reason === "max_tokens" ? "length" : reason === "refusal" ? "content-filter" : reason === "tool-calls" ? "tool-calls" : reason === "end_turn" || reason === "cancelled" ? "stop" : "other", raw: reason }
}
export function make(tools: readonly LanguageModelV3FunctionTool[] = []) {
  const usage = AgyUsage.make()
  let block: { kind: "text" | "reasoning"; id: string } | undefined
  const native = new Map<string, { name: string; input: unknown; emitted: boolean }>()
  const ignored = new Set<string>()
  const close = (): LanguageModelV3StreamPart[] => {
    if (!block) return []
    const previous = block; block = undefined
    return [{ type: `${previous.kind}-end`, id: previous.id }]
  }
  const finish = (reason: string): LanguageModelV3StreamPart[] => [...close(), { type: "finish", finishReason: finishReason(reason), usage: usage.snapshot() }]
  const convert = (event: SessionEvent): LanguageModelV3StreamPart[] => {
    if (event.type === "tool") return [...close(), { type: "tool-call", toolCallId: event.call.id, toolName: event.call.name, input: JSON.stringify(event.call.input) }, ...finish("tool-calls")]
    if (event.type === "result") { usage.result(event.result.usage); return finish(event.result.stopReason) }
    const update = event.update
    if (update.sessionUpdate === "usage_update") { usage.update(update); return [] }
    if (update.sessionUpdate === "agent_message_chunk" || update.sessionUpdate === "agent_thought_chunk") {
      const content = update.content as ObjectValue | undefined
      if (content?.type !== "text" || typeof content.text !== "string") return []
      const kind = update.sessionUpdate === "agent_message_chunk" ? "text" : "reasoning"
      const parts: LanguageModelV3StreamPart[] = []
      if (block?.kind !== kind) {
        parts.push(...close()); block = { kind, id: randomUUID() }
        parts.push({ type: `${kind}-start`, id: block.id })
      }
      parts.push({ type: `${kind}-delta`, id: block!.id, delta: content.text })
      return parts
    }
    if (update.sessionUpdate !== "tool_call" && update.sessionUpdate !== "tool_call_update") return []
    const id = String(update.toolCallId ?? "")
    if (!id || ignored.has(id)) return []
    const meta = update._meta as { mcp?: { server?: string; tool?: string } } | undefined
    if (meta?.mcp?.server === "opencode" || (meta?.mcp?.tool && ToolNames.original(meta.mcp.tool, tools))) {
      ignored.add(id); return []
    }
    let call = native.get(id)
    if (!call) {
      // A bridged call's final "completed" update carries no MCP tag and can land in a later OpenCode step,
      // where this converter never saw it begin. Native calls always start with a tool_call, so skip it.
      if (update.sessionUpdate === "tool_call_update") { ignored.add(id); return [] }
      call = { name: typeof update.title === "string" ? update.title : "antigravity_tool", input: update.rawInput ?? {}, emitted: false }
      native.set(id, call)
    }
    if (update.rawInput !== undefined) call.input = update.rawInput
    const parts = close()
    if (!call.emitted) {
      call.emitted = true
      parts.push({ type: "tool-call", toolCallId: id, toolName: call.name, input: JSON.stringify(call.input), providerExecuted: true, dynamic: true })
    }
    if (update.status === "completed" || update.status === "failed") {
      const result = JSON.parse(JSON.stringify(update.rawOutput ?? update.content ?? [])) as JSONValue
      // V3 results are intrinsically provider-executed; preserve the explicit flag for host consumers too.
      parts.push({ type: "tool-result", toolCallId: id, toolName: call.name, result: result ?? [], isError: update.status === "failed", dynamic: true, ...{ providerExecuted: true } })
      native.delete(id); ignored.add(id)
    }
    return parts
  }
  return { convert, finish, close, usage }
}
