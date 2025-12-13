{ inputs, config, lib, pkgs, ...}:
let

  system = pkgs.system;

  mcpServers =
    (with inputs.mcp-servers-nix.packages.${system}; [
      context7-mcp
      mcp-server-fetch
      mcp-server-sequential-thinking
    ])
    ++ (with pkgs; [
      mcp-nixos
      terraform-mcp-server
      # mcp-grafana
      # playwright-mcp
    ]);

  llmAgents = with inputs.llm-agents.packages.${system}; [];

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

  programs.opencode = {
    enable = true;
    package = inputs.llm-agents.packages.${system}.opencode;
    enableMcpIntegration = true;
    rules = '' 
      NEVER include your own emotes in your response
    '';
    commands = {
      rebuild-switch = ''
        Rebuild and switch to NixOS flake configuration defined for current machine.
        Usage: /rebuild-switch
      '';
    };
    settings = {
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = true;
        };

        mcp_nixos = {
          type = "local";
          command = [ "mcp-nixos" ];
          enabled = true;
        };

        terraform = {
          type = "local";
          command = [ "terraform-mcp-server" ];
          enabled = true;
        };

        fetch = {
          type = "local";
          command = [ "mcp-server-fetch" ];
          enabled = true;
        };

        sequential_thinking = {
          type = "local";
          command = [ "mcp-server-sequential-thinking" ];
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
          "*" = "ask";
          "sudo*" = "deny";
        };
        bash = {
          "*" = "ask";
          "sudo*" = "deny";
        };
      };
      agent = {
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
        claude = {
          npm = "@ai-sdk/openai-compatible";
          name = "Claude (work)";
          options = {
            baseURL = "http://10.0.0.122:11434/v1";
          };

          models = {
            "qwen3-coder:30b-32k" = { name = "Qwen3-coder 30B-32k (local)"; tool_call = true; };
          };
        };
      };
      model = "qwen3-coder:30b-32k";
    };
  };
}
