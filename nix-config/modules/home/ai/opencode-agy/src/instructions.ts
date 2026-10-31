import type { Plugin } from "@opencode/plugin"
import { ID } from "./provider.js"
import { AGENT_OPTION, INSTRUCTIONS_OPTION } from "./language-model/system-prompt.js"
export function instructions(system: ReadonlyArray<{ text: string; metadata?: unknown }>) {
  const texts: string[] = []
  for (const part of system.slice(1)) {
    const metadata = part.metadata as { experimental?: { instructions?: Array<{ key: string; text: string }> } } | undefined
    const sources = metadata?.experimental?.instructions
    if (!Array.isArray(sources)) { texts.push(part.text); continue }
    for (const source of sources) if (!["core/date", "core/environment"].includes(source.key)) texts.push(source.text)
  }
  return texts.join("\n\n")
}
export async function register(ctx: Plugin.Context) {
  for (const kind of ["context", "generate", "compaction"] as const) {
    await ctx.session.hook(kind, async (event) => {
      const agent = await ctx.agent.get({ agentID: event.agent })
      event.options[AGENT_OPTION] = agent.data.system ?? ""
      event.options[INSTRUCTIONS_OPTION] = instructions(event.system)
    }, { providerID: ID })
  }
}
