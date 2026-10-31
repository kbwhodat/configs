export * as RequestKind from "./request-kind.js"
export const HEADER = "x-opencode-agy-kind"
export const SESSION_HEADER = "x-opencode-session-id"
export const FORK_HEADER = "x-opencode-agy-fork-source"
export type Kind = "primary" | "title" | "summary" | "generate" | "compaction"
export function parse(value: string | undefined): Kind {
  return value === "primary" || value === "title" || value === "summary" || value === "compaction" ? value : "generate"
}
