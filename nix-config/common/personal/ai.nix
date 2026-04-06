{ inputs, config, lib, pkgs, ...}:
let

  system = pkgs.system;

  mcpServers =
    (with inputs.mcp-servers-nix.packages.${system}; [
      context7-mcp
      mcp-server-fetch
      mcp-server-sequential-thinking
      serena
    ])
    ++ (with pkgs; [
      mcp-nixos
      terraform-mcp-server
      # mcp-grafana
      playwright-mcp
    ]);

  llmAgents = with inputs.llm-agents.packages.${system}; [];
  ocv = inputs.ocv.packages.${system}.opencode;

  opencodeDir = "${config.home.homeDirectory}/.config/opencode";

  # packageJson = builtins.toJSON {
  #   dependencies = {
  #     "oh-my-opencode" = "^3.9.0";
  #   };
  # };
  #
  # packageJsonFile = pkgs.writeText "opencode-package.json" packageJson;

in
{
  home = {
    packages =
      with pkgs;
      [
        (if builtins.getEnv "HOST" == "nixos-server" then mistral-rs else nil)
        (if builtins.getEnv "HOST" == "nixos-server" then rlama else nil)
        (if builtins.getEnv "HOST" == "nixos-server" then python313Packages.huggingface-hub else nil)
        (pkgs.writeShellScriptBin "ocv" ''
          exec ${ocv}/bin/opencode "$@"
        '')
      ]
      ++ mcpServers
      ++ llmAgents;
  };

  # ecc-universal ships uncompiled TypeScript and no main field in package.json.
  # This activation hook drops a plain JS shim that registers skills + commands,
  # and sets main so opencode can load the plugin.
  home.activation.patchEccPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ECC_DIR="${config.home.homeDirectory}/.cache/opencode/node_modules/ecc-universal"
    if [ -d "$ECC_DIR" ]; then
      cat > "$ECC_DIR/ecc-opencode-shim.js" << 'SHIMEOF'
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const eccSkillsDir = path.resolve(__dirname, "skills");
const eccOpenCodeDir = path.resolve(__dirname, ".opencode");

function loadEccConfig() {
  const configPath = path.join(eccOpenCodeDir, "opencode.json");
  if (!fs.existsSync(configPath)) return null;
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function resolveFileRefs(obj, baseDir) {
  if (typeof obj === "string") {
    const match = obj.match(/^\{file:(.+)\}$/);
    if (match) {
      const filePath = path.join(baseDir, match[1]);
      if (fs.existsSync(filePath)) return fs.readFileSync(filePath, "utf8");
    }
    return obj;
  }
  if (Array.isArray(obj)) return obj.map(v => resolveFileRefs(v, baseDir));
  if (obj && typeof obj === "object") {
    const out = {};
    for (const [k, v] of Object.entries(obj)) out[k] = resolveFileRefs(v, baseDir);
    return out;
  }
  return obj;
}

export default async ({ client, directory }) => {
  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (fs.existsSync(eccSkillsDir) && !config.skills.paths.includes(eccSkillsDir)) {
        config.skills.paths.push(eccSkillsDir);
      }

      const ecc = loadEccConfig();
      if (!ecc) return;

      if (ecc.agent) {
        config.agent = config.agent || {};
        for (const [name, def] of Object.entries(ecc.agent)) {
          if (name === "build") {
            config.agent["ecc-build"] = resolveFileRefs(def, eccOpenCodeDir);
          } else if (!config.agent[name]) {
            config.agent[name] = resolveFileRefs(def, eccOpenCodeDir);
          }
        }
      }

      if (ecc.command) {
        config.command = config.command || {};
        for (const [name, def] of Object.entries(ecc.command)) {
          if (!config.command[name]) {
            config.command[name] = resolveFileRefs(def, eccOpenCodeDir);
          }
        }
      }
    },
  };
};
SHIMEOF

      ${pkgs.python3}/bin/python3 -c "
import json
p = '$ECC_DIR/package.json'
with open(p) as f: d = json.load(f)
if d.get('main') != 'ecc-opencode-shim.js':
    d['main'] = 'ecc-opencode-shim.js'
    with open(p, 'w') as f: json.dump(d, f, indent=2)
"
    fi
  '';

  programs.opencode = {
    enable = true;
    package = ocv;
    enableMcpIntegration = true;
    rules = ''
    '';
    commands = {
      rebuild-switch = ''
        Rebuild and switch to NixOS flake configuration defined for current machine.
        Usage: /rebuild-switch
      '';
    };

    skills = {
      # Core engineering skills
      # debugging-root-cause        = builtins.readFile ./skills/debugging-root-cause;
      # performance-engineering     = builtins.readFile ./skills/performance-engineering;
      # Mobile/project-specific skills
    };
    settings = {
      plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" "ecc-universal@git+https://github.com/affaan-m/everything-claude-code.git" ];
      keybinds = {
        messages_half_page_up = "ctrl+alt+u";
        messages_half_page_down = "ctrl+alt+d";
        messages_line_up = "ctrl+alt+y";
        messages_line_down = "ctrl+alt+e";
      };

      mcp = {
        # Disabled by default - enable with "use context7" in prompt
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = false;
        };

        mcp_nixos = {
          type = "local";
          command = [ "mcp-nixos" ];
          enabled = false;
        };

        # Disabled by default - enable with "use terraform" in prompt
        terraform = {
          type = "local";
          command = [ "terraform-mcp-server" ];
          enabled = false;
        };

        fetch = {
          type = "local";
          command = [ "mcp-server-fetch" ];
          enabled = false;
        };

        playwright = {
          type = "local";
          command = [ "mcp-server-playwright" "--no-sandbox" ];
          enabled = true;
        };

        # Disabled by default - enable with "use sequential_thinking" in prompt  
        sequential_thinking = {
          type = "local";
          command = [ "mcp-server-sequential-thinking" ];
          enabled = false;
        };

        # Enabled by default for token-efficient code navigation
        serena = {
          type = "local";
          command = [ "serena" "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ];
          enabled = true;
        };

        # Enabled by default for narrow code retrieval
        jcodemunch = {
          type = "local";
          command = [ "jcodemunch" ];
          enabled = false;
        };

      };
      autoshare = false;
      autoupdate = false;
      permission = {
        webfetch = "allow";
        grep = "allow";
        read = "allow";
        zsh = {
          "*" = "allow";
          "rm*" = "ask";
          "rmdir*" = "ask";
          "unlink*" = "ask";
          "mv*" = "ask";
          "sudo*" = "deny";
        };
        bash = {
          "*" = "allow";
          "rm*" = "ask";
          "rmdir*" = "ask";
          "unlink*" = "ask";
          "mv*" = "ask";
          "sudo*" = "deny";
        };
      };
      agent = {
        perftutor = {
          mode = "primary";
          description = "Perf Tutor Agent";
          prompt = builtins.readFile ./prompts/perftutor.txt;
          tools = {
            write = true;
            read = true;
            edit = true;
            bash = true;
          };
          temperature = 0.25;
        };
        perfguru = {
          mode = "primary";
          description = "Perf Guru Agent";
          prompt = builtins.readFile ./prompts/perfguru.txt;
          tools = {
            write = true;
            read = true;
            edit = true;
            bash = true;
          };
          temperature = 0.25;
        };
        planner = {
          mode = "subagent";
          description = "Expert planning specialist for complex features and refactoring";
          prompt = builtins.readFile ./prompts/planner.txt;
          tools = {
            read = true;
            bash = true;
          };
        };
        tdd-guide = {
          mode = "subagent";
          description = "TDD specialist enforcing test-first development with Red-Green-Refactor";
          prompt = builtins.readFile ./prompts/tdd-guide.txt;
          tools = {
            write = true;
            read = true;
            edit = true;
            bash = true;
          };
        };
    };


    };
  };
}
