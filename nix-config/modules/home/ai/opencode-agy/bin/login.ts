import { spawn } from "node:child_process"
import { mkdir, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"
import { AcpProcess } from "../src/acp/process.js"

/** The official server owns OAuth. Never inspect its credential store. */
export async function login(options: { dryRun?: boolean; serverPath?: string; directory?: string } = {}) {
  // Server stderr is echoed so the user sees the login URL or the reason a login failed.
  const acp = new AcpProcess({
    directory: options.directory ?? process.cwd(),
    serverPath: options.serverPath,
    log: (line) => {
      console.error("[agy-acp] " + line)
      // The server prints the Google URL instead of opening it; open it so the ~5 minute window is not wasted.
      const url = line.match(/https:\/\/accounts\.google\.com\/\S+/)?.[0]
      if (url && !options.dryRun) spawn(process.platform === "darwin" ? "open" : "xdg-open", [url], { stdio: "ignore", detached: true }).unref()
    },
  })
  try {
    const init = await acp.initialize()
    console.log(`ACP protocol: ${init.protocolVersion}`)
    console.log("Auth methods: " + init.authMethods.map((method) => method.id).join(", "))
    if (options.dryRun) { console.log("Dry run: initialize only; authenticate was not called."); return init }
    if (!init.authMethods.some((method) => method.id === "oauth-personal")) throw new Error("The ACP server does not offer oauth-personal")
    console.log("Complete the Google sign-in in your browser. Waiting for the ACP server to confirm...")
    await acp.request("authenticate", { methodId: "oauth-personal" })
    const directory = join(homedir(), ".gemini/antigravity-acp")
    await mkdir(directory, { recursive: true, mode: 0o700 })
    try { await writeFile(join(directory, "settings.json"), JSON.stringify({ auth: { type: "oauth-personal" } }) + "\n", { flag: "wx", mode: 0o600 }) }
    catch (error) { if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error }
    console.log("Antigravity login completed. Credentials remain managed by the official ACP server.")
    return init
  } finally { acp.stop() }
}
if (import.meta.main) {
  const unknown = process.argv.slice(2).filter((arg) => arg !== "--dry-run")
  if (unknown.length) { console.error("Usage: bun run bin/login.ts [--dry-run]"); process.exitCode = 1 }
  else await login({ dryRun: process.argv.includes("--dry-run") }).catch((error) => {
    // Print the message only, never `data`, which could carry login payloads.
    console.error(error instanceof Error ? `${error.name}: ${error.message}` : "Antigravity login failed")
    process.exitCode = 1
  })
}
