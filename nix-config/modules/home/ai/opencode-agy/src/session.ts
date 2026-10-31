import type { Plugin } from "@opencode/plugin"
import { ID } from "./provider.js"
import { HEADER, SESSION_HEADER, FORK_HEADER } from "./language-model/request-kind.js"
export async function register(ctx: Plugin.Context) {
  await ctx.session.hook("model.request", async (event) => {
    event.headers[HEADER] = event.kind
    event.headers[SESSION_HEADER] = event.sessionID
    if (event.kind !== "primary") return
    const session = await ctx.session.get({ sessionID: event.sessionID })
    if (session.fork) event.headers[FORK_HEADER] = session.fork.sessionID
  }, { providerID: ID })
  await ctx.session.hook("retry", (event) => { event.decision = { retry: false } }, { providerID: ID })
  await ctx.session.hook("context", (event) => {
    delete event.options.maxTokens
    event.messages = event.messages.map((message) => ({ ...message, content: message.content.map((part) => {
      if (part.type !== "tool-result" || part.result.type !== "error") return part
      const value = part.result.value as { error?: { type?: string } } | undefined
      return { ...part, providerMetadata: { ...part.providerMetadata, agy: { ...part.providerMetadata?.agy, toolError: true, toolAborted: value?.error?.type === "aborted" } } }
    }) }))
  }, { providerID: ID })
}
