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
      # jcodemunch
    ]);

  llmAgents = with inputs.llm-agents.packages.${system}; [];

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
      ]
      ++ mcpServers
      ++ llmAgents;
  };

  # Declaratively manage opencode plugins via package.json
  # This ensures oh-my-opencode is installed on all machines
  # home.activation.opencodeDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   mkdir -p "${opencodeDir}"
  #   cp -f "${packageJsonFile}" "${opencodeDir}/package.json"
  #   chmod u+w "${opencodeDir}/package.json" || true
  #   ${pkgs.bun}/bin/bun install --cwd "${opencodeDir}"
  #   '';

  programs.opencode = {
    enable = true;
    package = inputs.llm-agents.packages.${system}.opencode;
    enableMcpIntegration = true;
    rules = ''
      NEVER include your own emotes in your response

      In this repository, optimize hard for token efficiency.

      Rules:
      - Never read full files unless strictly necessary.
      - Use the smallest possible span for reasoning and edits.
      - Do not re-read code already retrieved.
      - Expand context gradually, not all at once.
      - Full-file reads need strong justification.
      - Prefer multiple small tool calls over one giant read.
      - Treat token budget as scarce.
      - Focus on using Serena mcp for everything

    '';
    commands = {
      rebuild-switch = ''
        Rebuild and switch to NixOS flake configuration defined for current machine.
        Usage: /rebuild-switch
      '';
    };

    skills = {
      # Core engineering skills
      architecture-decisions      = builtins.readFile ./skills/architecture-decisions;
      complexity-taming           = builtins.readFile ./skills/complexity-taming;
      debugging-root-cause        = builtins.readFile ./skills/debugging-root-cause;
      performance-engineering     = builtins.readFile ./skills/performance-engineering;
      security-data-handling      = builtins.readFile ./skills/security-data-handling;
      ship-it-checklist           = builtins.readFile ./skills/ship-it-checklist;
      supabase-database-mastery   = builtins.readFile ./skills/supabase-database-mastery;
      testing-verification        = builtins.readFile ./skills/testing-verification;
      # Mobile/project-specific skills
      dating-app-mvp              = builtins.readFile ./skills/dating-app-mvp;
      flutter-ui-design           = builtins.readFile ./skills/flutter-ui-design;
    };
    settings = {
      # plugin = [ "oh-my-opencode" ];
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
          enabled = true;
        };

        playwright = {
          type = "local";
          command = [ "mcp-server-playwright" "--no-sandbox" ];
          enabled = false;
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
          command = [ "serena" "start-mcp-server" "--context" "claude-code" ];
          enabled = true;
        };

        # Enabled by default for narrow code retrieval
        jcodemunch = {
          type = "local";
          command = [ "jcodemunch" ];
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
        debug = {
          mode = "primary";
          description = "Code Debugging Agent";
          prompt = builtins.readFile ./prompts/debug.txt;
          tools = {
            write = true;
            read = true;
            edit = true;
            bash = true;
          };
          temperature = 0.35;
        };
      sensei = {
        mode = "primary";
        description = "Sensei Agent";
        prompt = builtins.readFile ./prompts/sensei.txt;
        tools = {
          read = true;
          bash = true;
          edit = false;
          write = false;
        };
         temperature = 0.3;
       };
        risk-destroyer = {
          mode = "primary";
          description = "Risk Destroyer";
          prompt = builtins.readFile ./prompts/risk-destroyer.txt;
          tools = {
            write = false;
            read = true;
            edit = false;
            bash = true;
          };
          temperature = 0.2;
        };
      quant-planner = {
        mode = "primary";
        description = "Quant Planner";
        prompt = builtins.readFile ./prompts/quant-research-planner.txt;
        tools = {
          read = true;
          bash = true;
          edit = false;
          write = false;
        };
         temperature = 0.2;
       };
      quant-builder = {
        mode = "primary";
        description = "Quant Builder";
        prompt = builtins.readFile ./prompts/quant-strategy-builder.txt;
        tools = {
          read = true;
          bash = true;
          edit = true;
          write = true;
        };
         temperature = 0.25;
       };
    };

      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = {
            baseURL = "http://10.0.0.122:11434/v1";
          };

          models = {
            "qwen3-coder:30b-32k" = { name = "Qwen3-coder 30B-32k (local)"; tool_call = true; };
          };
        };
        glm = {
          npm = "@ai-sdk/openai-compatible";
          name = "nemotron-3-nano";
          options = {
            baseURL = "http://10.0.0.122:11434/v1";
          };

          models = {
            "nemotron-3-nano" = { 
              name = "nemotron-3-nano (local)"; 
              tool_call = true;
            };
          };
        };
      };
      model = "glm-4.7-flash:32b-32k";
      # provider = {
      #   ollama = {
      #     npm = "@ai-sdk/openai-compatible";
      #     name = "Ollama (local)";
      #     options = {
      #       baseURL = "http://10.0.0.122:11434/v1";
      #     };
      #
      #     models = {
      #       "qwen3-coder:30b-32k" = { name = "Qwen3-coder 30B-32k (local)"; tool_call = true; };
      #     };
      #   };
      #   claude = {
      #     npm = "@ai-sdk/openai-compatible";
      #     name = "Claude (work)";
      #     options = {
      #       baseURL = "http://10.0.0.122:11434/v1";
      #     };

          # models = {
          #   "qwen3-coder:30b-32k" = { name = "Qwen3-coder 30B-32k (local)"; tool_call = true; };
          # };
      #   };
      # };
      # model = "qwen3-coder:30b-32k";
    };
  };
}
