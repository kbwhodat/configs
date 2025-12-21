{ pkgs, lib, ... }:

let
  # Script to setup agenticSeek
  agenticseek-setup = pkgs.writeShellScriptBin "agenticseek-setup" ''
    set -e
    AGENTICSEEK_DIR="''${HOME}/.local/share/agenticseek"
    
    if [ ! -d "$AGENTICSEEK_DIR" ]; then
      echo "Cloning agenticSeek..."
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/Fosowl/agenticSeek.git "$AGENTICSEEK_DIR"
      cd "$AGENTICSEEK_DIR"
      cp .env.example .env
      
      # Configure .env with your ollama settings
      ${pkgs.gnused}/bin/sed -i 's|OLLAMA_PORT="11434"|OLLAMA_PORT="11434"|' .env
      
      # Configure config.ini for your ollama server
      # Note: is_local=True uses OLLAMA_HOST env var, is_local=False prepends http:// to server_address
      ${pkgs.gnused}/bin/sed -i 's|provider_server_address = .*|provider_server_address = 10.0.0.122:11434|' config.ini
      ${pkgs.gnused}/bin/sed -i 's|is_local = .*|is_local = False|' config.ini
      ${pkgs.gnused}/bin/sed -i 's|provider_name = .*|provider_name = ollama|' config.ini
      
      echo ""
      echo "agenticSeek installed to $AGENTICSEEK_DIR"
      echo "Config has been set to use ollama at http://10.0.0.122:11434"
      echo ""
      echo "You may want to edit:"
      echo "  - $AGENTICSEEK_DIR/.env (set WORK_DIR to your workspace)"
      echo "  - $AGENTICSEEK_DIR/config.ini (set provider_model, agent_name, etc.)"
    else
      echo "agenticSeek already installed at $AGENTICSEEK_DIR"
      echo "Updating..."
      cd "$AGENTICSEEK_DIR"
      ${pkgs.git}/bin/git pull
    fi
  '';

  # Start services (web interface mode)
  agenticseek-start = pkgs.writeShellScriptBin "agenticseek-start" ''
    AGENTICSEEK_DIR="''${HOME}/.local/share/agenticseek"
    
    if [ ! -d "$AGENTICSEEK_DIR" ]; then
      echo "agenticSeek not found. Run 'agenticseek-setup' first."
      exit 1
    fi
    
    cd "$AGENTICSEEK_DIR"
    ${pkgs.bash}/bin/bash ./start_services.sh full
  '';

  # Start services (CLI mode - services only)
  agenticseek-services = pkgs.writeShellScriptBin "agenticseek-services" ''
    AGENTICSEEK_DIR="''${HOME}/.local/share/agenticseek"
    
    if [ ! -d "$AGENTICSEEK_DIR" ]; then
      echo "agenticSeek not found. Run 'agenticseek-setup' first."
      exit 1
    fi
    
    cd "$AGENTICSEEK_DIR"
    ${pkgs.bash}/bin/bash ./start_services.sh
  '';

  # Run CLI
  agenticseek-cli = pkgs.writeShellScriptBin "agenticseek-cli" ''
    AGENTICSEEK_DIR="''${HOME}/.local/share/agenticseek"
    
    if [ ! -d "$AGENTICSEEK_DIR" ]; then
      echo "agenticSeek not found. Run 'agenticseek-setup' first."
      exit 1
    fi
    
    cd "$AGENTICSEEK_DIR"
    
    # Ensure SEARXNG_BASE_URL is set for CLI mode (running on host)
    export SEARXNG_BASE_URL="http://localhost:8080"
    
    # Set ollama host for remote ollama server
    export OLLAMA_HOST="http://10.0.0.122:11434"
    
    # Set up environment for native dependencies (pyaudio needs portaudio)
    export CPATH="${pkgs.portaudio}/include:$CPATH"
    export LIBRARY_PATH="${pkgs.portaudio}/lib:$LIBRARY_PATH"
    export LD_LIBRARY_PATH="${pkgs.portaudio}/lib:$LD_LIBRARY_PATH"
    export PKG_CONFIG_PATH="${pkgs.portaudio}/lib/pkgconfig:$PKG_CONFIG_PATH"
    
    ${pkgs.uv}/bin/uv run cli.py
  '';

  # Stop services
  agenticseek-stop = pkgs.writeShellScriptBin "agenticseek-stop" ''
    AGENTICSEEK_DIR="''${HOME}/.local/share/agenticseek"
    
    if [ ! -d "$AGENTICSEEK_DIR" ]; then
      echo "agenticSeek not found."
      exit 1
    fi
    
    cd "$AGENTICSEEK_DIR"
    ${pkgs.docker}/bin/docker compose down
  '';

in
{
  home.packages = [
    # agenticSeek helper scripts
    agenticseek-setup
    agenticseek-start
    agenticseek-services
    agenticseek-cli
    agenticseek-stop
    
    # Required dependencies
    pkgs.uv
    pkgs.portaudio      # Required for pyaudio
    pkgs.pkg-config     # Helps find native libraries
  ];
}
