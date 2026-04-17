{ inputs, config, lib, pkgs, ...}:
let

  system = pkgs.stdenv.hostPlatform.system;

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

  # Prebuilt ocv binary from upstream releases — bypasses the broken FOD
  # node_modules hash in upstream's flake. Bump version + sha256s when
  # moving to a new release tag.
  ocvRelease = "v1.14.25-ocv.3.28";
  ocvAssets = {
    "aarch64-darwin" = {
      asset = "ocv-darwin-arm64";
      sha256 = "d81f5a159dffc5126aa861385ed105adf7420f1e299ca32529c4a33d06d448a8";
    };
    "x86_64-darwin" = {
      asset = "ocv-darwin-x64";
      sha256 = "72a78491aaa621f6ef47d09a6a8f9d322e69a5dab505250246a4354b00d8cb1a";
    };
    "aarch64-linux" = {
      asset = "ocv-linux-arm64";
      sha256 = "b3f6bbe99d6fb9c5a74c76f6489dea8636e3b8c07826956469c2580494eb56d0";
    };
    "x86_64-linux" = {
      asset = "ocv-linux-x64";
      sha256 = "338c89d95bada61965fed79099360ce853b8875522805c0bbe19f20beff152e7";
    };
  };
  ocvBinary = let
    a = ocvAssets.${system};
    src = pkgs.fetchurl {
      url = "https://github.com/leohenon/opencode-vim/releases/download/${ocvRelease}/${a.asset}";
      sha256 = a.sha256;
    };
  in pkgs.stdenvNoCC.mkDerivation {
    pname = "opencode";
    version = lib.removePrefix "v" ocvRelease;
    inherit src;
    dontUnpack = true;
    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];
    installPhase = ''
      mkdir -p $out/bin
      install -m755 $src $out/bin/opencode
    '';
  };


  unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };

  opencodeDir = "${config.home.homeDirectory}/.config/opencode";
  claudeHookPath = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";

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
        unstable.rtk # CLI proxy that reduces LLM token consumption by 60-90% on common dev commands
        (if builtins.getEnv "HOST" == "nixos-server" then mistral-rs else nil)
        (if builtins.getEnv "HOST" == "nixos-server" then rlama else nil)
        (if builtins.getEnv "HOST" == "nixos-server" then python313Packages.huggingface-hub else nil)
        # (pkgs.writeShellScriptBin "ocv" ''
        #   exec ${ocv}/bin/opencode "$@"
        # '')
      ]
      ++ mcpServers
      ++ llmAgents;

  };

  # RTK OpenCode plugin — install hook for token-compressed bash output
  home.activation.installRtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${opencodeDir}/plugins/rtk.ts" ]; then
      ${unstable.rtk}/bin/rtk init -g --opencode --auto-patch 2>/dev/null || true
    fi
  '';

  # RTK Claude Code hook — hook-only install because settings are managed in Nix.
  home.activation.installRtkClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "${claudeHookPath}" ]; then
      ${unstable.rtk}/bin/rtk init -g --hook-only --no-patch 2>/dev/null || true
    fi
  '';

  # ecc-universal ships uncompiled TypeScript and no main field in package.json.
  # This activation hook drops a plain JS shim that registers skills + commands,
  # and sets main so opencode can load the plugin.
  home.activation.patchEccPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ECC_PKG_DIR="${config.home.homeDirectory}/.cache/opencode/packages/ecc-universal@git+https:/github.com/affaan-m/everything-claude-code.git/node_modules/ecc-universal"
    ECC_HOISTED_DIR="${config.home.homeDirectory}/.cache/opencode/node_modules/ecc-universal"
    for ECC_DIR in "$ECC_PKG_DIR" "$ECC_HOISTED_DIR"; do
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
    done
  '';

  programs.opencode = {
    enable = true;
    package = ocvBinary;
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

    skills = {
      # Core engineering skills
      # debugging-root-cause        = builtins.readFile ./skills/debugging-root-cause;
      # performance-engineering     = builtins.readFile ./skills/performance-engineering;
      # Mobile/project-specific skills
    };
    tui = {
      keybinds = {
        messages_half_page_up = "ctrl+alt+u";
        messages_half_page_down = "ctrl+alt+d";
        messages_line_up = "ctrl+alt+y";
        messages_line_down = "ctrl+alt+e";
      };
    };
    settings = {
      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git"
        "ecc-universal@git+https://github.com/affaan-m/everything-claude-code.git"
      ];

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

        firecrawl = {
          type = "local";
          command = [ "env" "FIRECRAWL_API_KEY=fc-b5db7738ea3843dd86181be770891120" "npx" "-y" "firecrawl-mcp" ];
          enabled = true;
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

        # Multi-board job search (20 sources). Direct binary launch matches
        # the proven serena/mcp-nixos pattern (single fork+exec, no uvx
        # wrapper). Binary installed by home.activation.installJobdrop below.
        jobdrop = {
          type = "local";
          command = [
            "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server"
          ];
          enabled = true;
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

  programs.claude-code = {
    enable = true;
    package = unstable.claude-code;

    marketplaces = {
      ecc = pkgs.fetchFromGitHub {
        owner = "affaan-m";
        repo = "everything-claude-code";
        rev = "main";
        sha256 = "sha256-FEqDiGcXgbi1UJNpbYlYS1EdlI83ksR66u5F0EKZncs=";
      };
      superpowers = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "main";
        sha256 = "sha256-cobQloF7Y6K0IC0/6xSnA2Io+fKgk2SRmCwoZZtVCco=";
      };
    };

    plugins = [
      (pkgs.fetchFromGitHub {
        owner = "affaan-m";
        repo = "everything-claude-code";
        rev = "main";
        sha256 = "sha256-FEqDiGcXgbi1UJNpbYlYS1EdlI83ksR66u5F0EKZncs=";
      })
      (pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "main";
        sha256 = "sha256-cobQloF7Y6K0IC0/6xSnA2Io+fKgk2SRmCwoZZtVCco=";
      })
    ];

    mcpServers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        disabled = true;
      };

      mcp_nixos = {
        command = "mcp-nixos";
        disabled = true;
      };

      terraform = {
        command = "terraform-mcp-server";
        disabled = true;
      };

      fetch = {
        command = "mcp-server-fetch";
        disabled = true;
      };

      firecrawl = {
        command = "env";
        args = [ "FIRECRAWL_API_KEY=fc-b5db7738ea3843dd86181be770891120" "npx" "-y" "firecrawl-mcp" ];
      };

      playwright = {
        command = "mcp-server-playwright";
        args = [ "--no-sandbox" ];
      };

      sequential_thinking = {
        command = "mcp-server-sequential-thinking";
        disabled = true;
      };

      serena = {
        command = "serena";
        args = [ "start-mcp-server" "--context" "claude-code" "--open-web-dashboard" "false" "--mode" "editing" "--mode" "interactive" ];
      };

      jcodemunch = {
        command = "jcodemunch";
        disabled = true;
      };

      # Multi-board job search (20 sources). Direct binary launch matches
      # the proven serena/mcp-nixos pattern (single fork+exec, no uvx
      # wrapper). Binary installed by home.activation.installJobdrop below.
      # Camoufox's Firefox binary is cached at ~/.cache/camoufox after
      # first call.
      jobdrop = {
        command = "${config.home.homeDirectory}/.local/bin/jobdrop-mcp-server";
      };
    };

    settings = {
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = claudeHookPath;
              }
            ];
          }
        ];
      };

      permissions = {
        allow = [
          "WebFetch"
          "Read"
          "Grep"
          "Bash"
          "Zsh"
        ];
        deny = [
          "Bash(sudo*)"
          "Zsh(sudo*)"
        ];
        ask = [
          "Bash(rm*)"
          "Bash(rmdir*)"
          "Bash(unlink*)"
          "Bash(mv*)"
          "Zsh(rm*)"
          "Zsh(rmdir*)"
          "Zsh(unlink*)"
          "Zsh(mv*)"
        ];
      };
    };
  };
}
