export const AUTH_HELP = "Not logged in to Google. Run `opencode auth login agy`."
export const MISSING_HELP = "Antigravity ACP server not found. Install agy-acp-server (Nix) or set OPENCODE_AGY_ACP_SERVER / provider option serverPath."
export function message(error: unknown): string {
  const text = error instanceof Error ? error.message : String(error)
  const code = error && typeof error === "object" && "code" in error ? error.code : undefined
  return code === -32000 || /auth_required|authentication required/i.test(text) ? AUTH_HELP : text
}
