import type { Plugin } from "@opencode/plugin"
import { Model, type Dependencies } from "./language-model/agy-language-model.js"
import { ID, PACKAGE } from "./provider.js"
export async function register(ctx: Plugin.Context, dependencies: Dependencies) {
  await ctx.aisdk.hook("sdk", (event) => {
    if (event.package !== PACKAGE) return
    event.sdk = { languageModel: (id: string) => new Model(id, dependencies, event.options) }
  }, { providerID: ID })
}
