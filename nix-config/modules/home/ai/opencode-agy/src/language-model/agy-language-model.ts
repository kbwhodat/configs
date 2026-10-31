import type {
  LanguageModelV3, LanguageModelV3CallOptions, LanguageModelV3Content, LanguageModelV3FunctionTool,
  LanguageModelV3GenerateResult, LanguageModelV3Prompt, LanguageModelV3StreamPart, LanguageModelV3StreamResult,
} from "@ai-sdk/provider"
import type { SessionEvent } from "../acp/session.js"
import { ConvertAcpStream } from "./convert-acp-stream.js"
import { RequestKind } from "./request-kind.js"
import { AgySystemPrompt } from "./system-prompt.js"
import { AgyError } from "./agy-error.js"
export * as AgyLanguageModel from "./agy-language-model.js"
export interface Request {
  sessionID?: string
  sourceID?: string
  kind: RequestKind.Kind
  model: string
  effort: "low" | "medium" | "high"
  system: string
  prompt: LanguageModelV3Prompt
  tools: readonly LanguageModelV3FunctionTool[]
  settings: Readonly<Record<string, unknown>>
  emit: (event: SessionEvent) => void
}
/** Phase 2 supplies the registry, persistence, prompt conversion, and continuation policy. */
export interface Dependencies { run: (request: Request, signal: AbortSignal) => Promise<void> }
export class Model implements LanguageModelV3 {
  static readonly SIDE_MODEL = "gemini-3.8-flash"
  readonly specificationVersion = "v3"
  readonly provider = "agy"
  readonly supportedUrls = {}
  constructor(readonly modelId: string, readonly dependencies: Dependencies, readonly settings: Readonly<Record<string, unknown>> = {}) {}
  async doStream(options: LanguageModelV3CallOptions): Promise<LanguageModelV3StreamResult> {
    const abort = new AbortController()
    const signal = options.abortSignal ? AbortSignal.any([abort.signal, options.abortSignal]) : abort.signal
    const kind = RequestKind.parse(options.headers?.[RequestKind.HEADER])
    const sessionID = kind === "primary" ? options.headers?.[RequestKind.SESSION_HEADER] : undefined
    const sourceID = options.headers?.[RequestKind.FORK_HEADER] ?? (kind !== "primary" ? options.headers?.[RequestKind.SESSION_HEADER] : undefined)
    if (kind === "primary" && !sessionID) throw new Error("Antigravity primary request is missing its OpenCode session id")
    const tools = kind === "primary" && options.toolChoice?.type !== "none" ? (options.tools ?? []).filter((tool): tool is LanguageModelV3FunctionTool => tool.type === "function") : []
    const settings = { ...this.settings, ...options.providerOptions?.agy }
    // Titles and summaries are throwaway side calls: Flash at low effort answers in ~2 s and spares the Argon quota.
    const side = kind === "title" || kind === "summary"
    const model = side ? Model.SIDE_MODEL : this.modelId
    const effort = side ? "low" : settings.effort ?? "medium"
    if (effort !== "low" && effort !== "medium" && effort !== "high") throw new Error("Antigravity effort must be low, medium or high")
    const convert = ConvertAcpStream.make(tools)
    let cancelled = false
    let task: Promise<void> | undefined
    let terminal = false
    const stream = new ReadableStream<LanguageModelV3StreamPart>({
      start: (controller) => {
        controller.enqueue({ type: "stream-start", warnings: [] })
        task = Promise.resolve().then(() => {
          if (signal.aborted) throw signal.reason ?? new Error("Aborted")
          return this.dependencies.run({
            sessionID, sourceID, kind, model, effort, settings,
            system: AgySystemPrompt.make(options.prompt, typeof settings[AgySystemPrompt.AGENT_OPTION] === "string" ? settings[AgySystemPrompt.AGENT_OPTION] as string : undefined,
              typeof settings[AgySystemPrompt.INSTRUCTIONS_OPTION] === "string" ? settings[AgySystemPrompt.INSTRUCTIONS_OPTION] as string : undefined),
            prompt: options.prompt, tools,
            emit(event) {
              if (cancelled || terminal) return
              for (const part of convert.convert(event)) {
                controller.enqueue(part)
                if (part.type === "finish") terminal = true
              }
            },
          }, signal)
        }).then(() => {
          if (cancelled) return
          if (!terminal) throw new Error("Antigravity registry ended without a result or tool boundary")
          controller.close()
        }).catch((error) => {
          if (cancelled) return
          if (!terminal) {
            for (const part of convert.close()) controller.enqueue(part)
            controller.enqueue({ type: "error", error: AgyError.readable(error) })
            controller.enqueue({ type: "finish", finishReason: { unified: "error", raw: "error" }, usage: convert.usage.snapshot() })
          }
          controller.close()
        })
      },
      cancel: () => { cancelled = true; abort.abort(); return task },
    })
    return { stream }
  }
  async doGenerate(options: LanguageModelV3CallOptions): Promise<LanguageModelV3GenerateResult> {
    const { stream } = await this.doStream(options)
    const content: LanguageModelV3Content[] = []
    const blocks = new Map<string, { type: "text" | "reasoning"; text: string }>()
    let finish: Extract<LanguageModelV3StreamPart, { type: "finish" }> | undefined
    const warnings: LanguageModelV3GenerateResult["warnings"] = []
    const reader = stream.getReader()
    try {
      while (true) {
        const { done, value: part } = await reader.read()
        if (done) break
        switch (part.type) {
          case "stream-start": warnings.push(...part.warnings); break
          case "text-start": case "reasoning-start": {
            const block = { type: part.type === "text-start" ? "text" as const : "reasoning" as const, text: "" }
            blocks.set(part.id, block); content.push(block); break
          }
          case "text-delta": case "reasoning-delta": {
            const block = blocks.get(part.id)
            if (block) block.text += part.delta
            break
          }
          case "tool-call": case "tool-result": case "file": case "source": case "tool-approval-request": content.push(part); break
          case "finish": finish = part; break
          case "error": throw AgyError.readable(part.error)
        }
      }
    } catch (error) { await reader.cancel().catch(() => {}); throw error }
    finally { reader.releaseLock() }
    if (!finish) throw new Error("Antigravity stream ended without usage and finish reason")
    return { content, finishReason: finish.finishReason, usage: finish.usage, warnings }
  }
}
