import type { LanguageModelV3Prompt } from "@ai-sdk/provider"
export * as AgySystemPrompt from "./system-prompt.js"
export const AGENT_OPTION = "agyAgent"
export const INSTRUCTIONS_OPTION = "agyInstructions"
export const RUNTIME_NOTE = "<runtime_info>You are running in OpenCode through the Antigravity harness. Mention this only when asked.</runtime_info>"
export const VERIFY_NOTE = "Verify any URL, file, product or name the user gives you before reasoning about it; never substitute a similar-looking one."
export function make(prompt: LanguageModelV3Prompt, agent?: string, instructions?: string) {
  return [RUNTIME_NOTE, VERIFY_NOTE, ...prompt.filter((message) => message.role === "system").map((message) => message.content),
    agent ? `# Agent role (from OpenCode)\n${agent}` : "", instructions ?? ""].filter(Boolean).join("\n\n")
}
export const utility = (prompt: LanguageModelV3Prompt) => make(prompt)
