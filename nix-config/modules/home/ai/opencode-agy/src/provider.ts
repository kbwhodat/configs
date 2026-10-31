import { Model, Provider, type Plugin } from "@opencode/plugin"
import type { SessionInfo } from "./acp/session.js"
export const ID = Provider.ID.make("agy")
export const PACKAGE = "opencode-agy"
export interface CatalogModel { id: string; name: string }
export interface Catalog { models: CatalogModel[] }
export function catalog(info: SessionInfo): Catalog {
  const models = new Map<string, CatalogModel>()
  for (const model of info.models?.availableModels ?? []) models.set(model.modelId, { id: model.modelId, name: model.name })
  const options = info.configOptions?.find((option) => option.id === "model")?.options ?? []
  for (const option of options.flatMap((option) => "value" in option ? [option] : option.options)) models.set(option.value, { id: option.value, name: option.name })
  return { models: [...models.values()] }
}
function toModel(item: CatalogModel): Model.Info {
  return {
    ...Model.Info.default(ID, Model.ID.make(item.id)), name: item.name,
    capabilities: { tools: true, input: ["text", "image", "pdf"], output: ["text", "reasoning"], temperature: false },
    limit: { context: 1_000_000, output: 65_536 }, cost: [],
    ...(["argon", "flash"].includes(item.id) ? { settings: { effort: "medium" }, variants: ["low", "medium", "high"].map((effort) => ({ id: Model.VariantID.make(effort), settings: { effort } })) } : {}),
  }
}
export async function register(ctx: Plugin.Context) {
  const saved: unknown = await ctx.storage.get("catalog")
  let current: Catalog = { models: [] }
  if (saved && typeof saved === "object" && "models" in saved && Array.isArray(saved.models)) {
    current.models = saved.models.filter((value): value is CatalogModel => !!value && typeof value === "object" && !Array.isArray(value) && typeof value.id === "string" && typeof value.name === "string")
  }
  await ctx.provider.transform((editor) => {
    const models = new Map<string, CatalogModel>([["argon", { id: "argon", name: "Gemini 4 Argon" }]])
    for (const model of current.models) models.set(model.id, model)
    if (current.models.some((model) => /^gemini-3[.-]8-flash/.test(model.id))) models.set("flash", { id: "flash", name: "Gemini 3.8 Flash" })
    editor.add({ info: { id: ID, name: "Antigravity (Google AI Pro)", activation: "enabled", package: `aisdk:${PACKAGE}` }, models: [...models.values()].map(toModel) })
  })
  return async (next: Catalog) => {
    if (JSON.stringify(next) === JSON.stringify(current)) return
    current = next
    await ctx.storage.set("catalog", { models: next.models.map((model) => ({ ...model })) })
    await ctx.provider.reload()
  }
}
