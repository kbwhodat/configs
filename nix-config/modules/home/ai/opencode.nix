{ config, lib, pkgs, inputs, ... }:
let cfg = config.modules.ai.opencode; in {
  options.modules.ai.opencode.enable = lib.mkEnableOption "opencode TUI + ECC patch hook";

  config = lib.mkIf cfg.enable {
    home.activation.patchEccPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ECC_PKG_DIR="${config.home.homeDirectory}/.cache/opencode/packages/ecc-universal@git+https:/github.com/affaan-m/everything-claude-code.git/node_modules/ecc-universal"
      ECC_HOISTED_DIR="${config.home.homeDirectory}/.cache/opencode/node_modules/ecc-universal"
      for ECC_DIR in "$ECC_PKG_DIR" "$ECC_HOISTED_DIR"; do
        if [ -d "$ECC_DIR" ]; then
          install -m644 ${./ecc-opencode-shim.js} "$ECC_DIR/ecc-opencode-shim.js"
          ${pkgs.python3}/bin/python3 -c "
      import json
      p = '$ECC_DIR/package.json'
      with open(p) as f: d = json.load(f)
      if d.get('main') != 'ecc-opencode-shim.js':
          d['main'] = 'ecc-opencode-shim.js'
          with open(p, 'w') as f: json.dump(d, f, indent=2)
      "
        fi
      done
    '';

    programs.opencode = {
      enable = true;
      package = pkgs.ocv;
      enableMcpIntegration = true;
      context = ''
        Do not use AskUserQuestion — that tool does not exist here. To ask the user a question, use the "question" tool instead.
      '';
      commands = {
        rebuild-switch = ''
          Rebuild and switch to NixOS flake configuration defined for current machine.
          Usage: /rebuild-switch
        '';
      };
      skills = {};
      tui.keybinds = {
        messages_half_page_up = "ctrl+alt+u";
        messages_half_page_down = "ctrl+alt+d";
        messages_line_up = "ctrl+alt+y";
        messages_line_down = "ctrl+alt+e";
      };
      settings = {
        plugin = [
          "superpowers@git+https://github.com/obra/superpowers.git"
          "ecc-universal@git+https://github.com/affaan-m/everything-claude-code.git"
        ];
        mcp = {
          context7 = { type = "remote"; url = "https://mcp.context7.com/mcp"; enabled = false; };
          mcp_nixos = { type = "local"; command = [ "mcp-nixos" ]; enabled = false; };
          terraform = { type = "local"; command = [ "terraform-mcp-server" ]; enabled = false; };
          fetch = { type = "local"; command = [ "mcp-server-fetch" ]; enabled = false; };
          firecrawl = { type = "local"; command = [ "env" "FIRECRAWL_API_KEY=fc-b5db7738ea3843dd86181be770891120" "npx" "-y" "firecrawl-mcp" ]; enabled = true; };
          playwright = { type = "local"; command = [ "mcp-server-playwright" "--no-sandbox" ]; enabled = true; };
          sequential_thinking = { type = "local"; command = [ "mcp-server-sequential-thinking" ]; enabled = false; };
          serena = { type = "local"; command = [ "serena" "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ]; enabled = true; };
          jcodemunch = { type = "local"; command = [ "jcodemunch" ]; enabled = false; };
          jobdrop = { type = "local"; command = [ "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server" ]; enabled = true; };
        };
        autoshare = false;
        autoupdate = false;
        permission = {
          webfetch = "allow";
          grep = "allow";
          read = "allow";
          zsh = { "*" = "allow"; "rm*" = "ask"; "rmdir*" = "ask"; "unlink*" = "ask"; "mv*" = "ask"; "sudo*" = "deny"; };
          bash = { "*" = "allow"; "rm*" = "ask"; "rmdir*" = "ask"; "unlink*" = "ask"; "mv*" = "ask"; "sudo*" = "deny"; };
        };
        agent = {
          perftutor = {
            mode = "primary";
            description = "Perf Tutor Agent";
            prompt = builtins.readFile ../../../common/personal/prompts/perftutor.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            temperature = 0.25;
          };
          perfguru = {
            mode = "primary";
            description = "Perf Guru Agent";
            prompt = builtins.readFile ../../../common/personal/prompts/perfguru.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
            temperature = 0.25;
          };
          planner = {
            mode = "subagent";
            description = "Expert planning specialist for complex features and refactoring";
            prompt = builtins.readFile ../../../common/personal/prompts/planner.txt;
            tools = { read = true; bash = true; };
          };
          tdd-guide = {
            mode = "subagent";
            description = "TDD specialist enforcing test-first development with Red-Green-Refactor";
            prompt = builtins.readFile ../../../common/personal/prompts/tdd-guide.txt;
            tools = { write = true; read = true; edit = true; bash = true; };
          };
        };
      };
    };
  };
}
