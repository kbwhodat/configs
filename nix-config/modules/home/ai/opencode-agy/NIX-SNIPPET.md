# Home Manager wiring

Add to `opencode.nix` (merge with existing bindings/settings; do not replace them):

```nix
let
  agy-acp-server = pkgs.callPackage ./opencode-agy/agy-acp-server.nix {};
in {
  home.packages = [ agy-acp-server pkgs.bun ];
  home.file.".config/opencode/plugins/agy".source = ./opencode-agy;
  # Merge into the attrset used to generate opencode.json(c):
  # plugins = [ "./plugins/agy" ];
  # providers.agy.settings.serverPath = "${agy-acp-server}/bin/agy-acp-server";
}
```

The exact native **V2** JSONC form, relative to `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "plugins": ["./plugins/agy"],
  "providers": {
    "agy": { "settings": { "serverPath": "/nix/store/…/bin/agy-acp-server" } }
  }
}
```

V2 uses `providers.agy.settings`, not deprecated V1 `provider.agy.options`.
A local directory is a plain relative/absolute path or `file:///…` URL, not an npm name.
Its `package.json` exports `.` to `./src/index.ts`.
Directories in global `plugins/` also auto-load; the explicit entry is supported and documents intent.
Source: https://opencode.ai/v2/docs/build/plugins/ and https://opencode.ai/v2/docs/config.

Run `opencode auth login`, choose **Antigravity (Google AI Pro)** and the official
Google login command. Alternatively, run `bun run bin/login.ts` in this directory.
The server, not OpenCode, owns credentials. Do not copy OAuth tokens into any config.
Login uses `OPENCODE_AGY_ACP_SERVER` or `agy-acp-server` on PATH; put the Nix package
on PATH even when configuring the provider's `serverPath` for model requests.
Avoid including a development `node_modules` in the Nix source; filter that directory
when packaging a checkout with installed development dependencies.
