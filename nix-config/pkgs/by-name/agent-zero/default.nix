{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  python313,
  python313Packages,
  fetchPypi,
  makeWrapper,
  # System deps needed at runtime
  ffmpeg,
  tesseract,
  poppler-utils,
  git,
  openssh,
  playwright-driver,
}:

let
  # Override Python package set to fix dlinfo test failure on macOS
  # (dlinfo tests look for /usr/lib/libdl.dylib which doesn't exist in the sandbox)
  python313' = python313.override {
    packageOverrides = _self: super: {
      # dlinfo tests look for /usr/lib/libdl.dylib which doesn't exist in the sandbox
      dlinfo = super.dlinfo.overridePythonAttrs {
        doCheck = false;
      };
      # accelerate tests crash with SIGTRAP on macOS (nixpkgs upstream issue)
      accelerate = super.accelerate.overridePythonAttrs {
        doCheck = false;
      };
    };
  };

  customPyDeps = import ./python-deps.nix {
    inherit lib stdenv fetchPypi;
    python313Packages = python313'.pkgs;
  };

  pythonEnv = python313'.withPackages (ps: with ps; [
    # --- From nixpkgs (46 packages) ---
    a2wsgi
    asgiref  # flask[async] extra
    beautifulsoup4
    boto3
    crontab
    ddgs
    docker
    exchangelib
    faiss
    fastmcp
    flask
    gitpython
    html2text
    imapclient
    kokoro
    langchain
    langchain-community
    langchain-core
    langchain-text-splitters
    litellm
    lxml-html-clean
    markdown
    markdownify
    mcp
    nest-asyncio
    newspaper3k
    openai
    openai-whisper
    paramiko
    pathspec
    pdf2image
    playwright
    psutil
    pydantic
    pymupdf
    pytesseract
    python-dotenv
    python-socketio
    pytz
    pypdf
    sentence-transformers
    simpleeval
    soundfile
    tiktoken
    unstructured
    unstructured-client
    uvicorn
    webcolors
    wsproto

    # --- Custom packages (11) ---
    customPyDeps.ansio
    customPyDeps.browser-use
    customPyDeps.bubus
    customPyDeps.fasta2a
    customPyDeps.flaredantic
    customPyDeps.flask-basicauth
    customPyDeps.inputimeout
    customPyDeps.langchain-unstructured
    customPyDeps.markdown-pdf
    customPyDeps.patchright
    customPyDeps.uuid7
  ]);

in stdenvNoCC.mkDerivation rec {
  pname = "agent-zero";
  version = "0.9.8.2";

  src = fetchFromGitHub {
    owner = "agent0ai";
    repo = "agent-zero";
    tag = "v${version}";
    hash = "sha256-0LAGOwtjdcjqsD5+UiBwi+Dpi5vBEBVYtf99ffWkaXA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  # Patch langchain imports for nixpkgs langchain >= 1.0.
  # agent-zero pins langchain-core==0.3.x but nixpkgs has 1.2.x which removed
  # many re-exports and deprecated classes (CacheBackedEmbeddings, LocalFileStore).
  # We create a compat shim and patch imports.
  postPatch = ''
    # Create compatibility shim for removed langchain classes
    cat > python/helpers/langchain_compat.py << 'COMPAT_EOF'
    """
    Compatibility shim for langchain classes removed in langchain >= 1.0.
    Provides InMemoryByteStore, LocalFileStore, and CacheBackedEmbeddings.
    """
    import hashlib
    import json
    import os
    from typing import Iterator, List, Optional, Sequence

    from langchain_core.embeddings import Embeddings


    class InMemoryByteStore:
        """Simple in-memory byte store."""

        def __init__(self):
            self.store = {}

        def mget(self, keys: Sequence[str]) -> List[Optional[bytes]]:
            return [self.store.get(k) for k in keys]

        def mset(self, key_value_pairs: Sequence[tuple]) -> None:
            for k, v in key_value_pairs:
                self.store[k] = v

        def mdelete(self, keys: Sequence[str]) -> None:
            for k in keys:
                self.store.pop(k, None)

        def yield_keys(self, prefix: Optional[str] = None) -> Iterator[str]:
            for k in self.store:
                if prefix is None or k.startswith(prefix):
                    yield k


    class LocalFileStore:
        """Simple file-based byte store."""

        def __init__(self, root_path: str):
            self.root_path = root_path
            os.makedirs(root_path, exist_ok=True)

        def _path(self, key: str) -> str:
            safe = hashlib.md5(key.encode()).hexdigest()
            return os.path.join(self.root_path, safe)

        def mget(self, keys: Sequence[str]) -> List[Optional[bytes]]:
            result = []
            for k in keys:
                p = self._path(k)
                if os.path.exists(p):
                    with open(p, "rb") as f:
                        result.append(f.read())
                else:
                    result.append(None)
            return result

        def mset(self, key_value_pairs: Sequence[tuple]) -> None:
            for k, v in key_value_pairs:
                with open(self._path(k), "wb") as f:
                    f.write(v if isinstance(v, bytes) else str(v).encode())

        def mdelete(self, keys: Sequence[str]) -> None:
            for k in keys:
                p = self._path(k)
                if os.path.exists(p):
                    os.remove(p)

        def yield_keys(self, prefix: Optional[str] = None) -> Iterator[str]:
            # Cannot reconstruct original keys from hashed filenames
            return iter([])


    class CacheBackedEmbeddings(Embeddings):
        """Caches embedding results in a byte store."""

        def __init__(self, embedder: Embeddings, store, namespace: str = ""):
            self.embedder = embedder
            self.store = store
            self.namespace = namespace

        @classmethod
        def from_bytes_store(cls, underlying_embeddings, document_embedding_cache, *, namespace=""):
            return cls(underlying_embeddings, document_embedding_cache, namespace=namespace)

        def _cache_key(self, text: str) -> str:
            h = hashlib.md5(text.encode()).hexdigest()
            return f"{self.namespace}{h}" if self.namespace else h

        def embed_documents(self, texts: List[str]) -> List[List[float]]:
            keys = [self._cache_key(t) for t in texts]
            cached = self.store.mget(keys)
            results = [None] * len(texts)
            uncached_indices = []
            uncached_texts = []

            for i, val in enumerate(cached):
                if val is not None:
                    results[i] = json.loads(val)
                else:
                    uncached_indices.append(i)
                    uncached_texts.append(texts[i])

            if uncached_texts:
                new_embeddings = self.embedder.embed_documents(uncached_texts)
                pairs = []
                for idx, emb in zip(uncached_indices, new_embeddings):
                    results[idx] = emb
                    pairs.append((keys[idx], json.dumps(emb).encode()))
                self.store.mset(pairs)

            return results  # type: ignore

        def embed_query(self, text: str) -> List[float]:
            return self.embed_documents([text])[0]

    COMPAT_EOF

    # Fix imports to use our compat shim
    substituteInPlace python/helpers/memory.py \
      --replace-fail \
        "from langchain.storage import InMemoryByteStore, LocalFileStore" \
        "from python.helpers.langchain_compat import InMemoryByteStore, LocalFileStore"
    substituteInPlace python/helpers/memory.py \
      --replace-fail \
        "from langchain.embeddings import CacheBackedEmbeddings" \
        "from python.helpers.langchain_compat import CacheBackedEmbeddings"

    substituteInPlace python/helpers/vector_db.py \
      --replace-fail \
        "from langchain.storage import InMemoryByteStore" \
        "from python.helpers.langchain_compat import InMemoryByteStore"
    substituteInPlace python/helpers/vector_db.py \
      --replace-fail \
        "from langchain.embeddings import CacheBackedEmbeddings" \
        "from python.helpers.langchain_compat import CacheBackedEmbeddings"

    # Create a bootstrap script that ignores SIGTRAP before importing agent-zero.
    # SIGTRAP is raised by litellm/openai async HTTP client cleanup on macOS ARM64.
    cat > nix_bootstrap.py << 'BOOTSTRAP'
    import signal, sys, os
    signal.signal(signal.SIGTRAP, signal.SIG_IGN)
    sys.path.insert(0, os.getcwd())
    exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "run_ui.py")).read())
    BOOTSTRAP

    # Patch get_base_dir() to use AGENT_ZERO_HOME env var instead of __file__,
    # so that mutable state (logs, usr, etc.) goes to the data dir instead of the Nix store.
    substituteInPlace python/helpers/files.py \
      --replace-fail \
        'base_dir = os.path.dirname(os.path.abspath(os.path.join(__file__, "../../")))' \
        'base_dir = os.environ.get("AGENT_ZERO_HOME", os.path.dirname(os.path.abspath(os.path.join(__file__, "../../"))))'

    # fastmcp >= 2.14 removed build_resource_metadata_url; provide a fallback
    substituteInPlace python/helpers/mcp_server.py \
      --replace-fail \
        "from fastmcp.server.http import create_sse_app, create_base_app, build_resource_metadata_url # type: ignore" \
        "from fastmcp.server.http import create_sse_app, create_base_app # type: ignore
    try:
        from fastmcp.server.http import build_resource_metadata_url
    except ImportError:
        def build_resource_metadata_url(url): return url.rstrip('/') + '/.well-known/oauth-protected-resource' if url else None"

    # langchain.prompts -> langchain_core.prompts
    substituteInPlace python/helpers/call_llm.py \
      --replace-fail "from langchain.prompts import" "from langchain_core.prompts import"

    # langchain.schema -> langchain_core.messages
    substituteInPlace python/helpers/call_llm.py \
      --replace-fail "from langchain.schema import AIMessage" "from langchain_core.messages import AIMessage"
    substituteInPlace python/helpers/document_query.py \
      --replace-fail "from langchain.schema import SystemMessage, HumanMessage" "from langchain_core.messages import SystemMessage, HumanMessage"

    # langchain.embeddings.base -> langchain_core.embeddings
    substituteInPlace models.py \
      --replace-fail "from langchain.embeddings.base import Embeddings" \
        "from langchain_core.embeddings import Embeddings"

    # langchain.text_splitter -> langchain_text_splitters
    substituteInPlace python/helpers/document_query.py \
      --replace-fail "from langchain.text_splitter import RecursiveCharacterTextSplitter" \
        "from langchain_text_splitters import RecursiveCharacterTextSplitter"
  '';

  installPhase = ''
    runHook preInstall

    # Install the application source tree (read-only in the Nix store)
    appdir=$out/lib/agent-zero
    mkdir -p $appdir $out/bin

    cp -r . $appdir/

    # Main launcher: sets up mutable working directory then runs the UI
    cat > $out/bin/agent-zero << 'EOF'
    #!/usr/bin/env bash
    set -euo pipefail

    A0_DATA="''${AGENT_ZERO_DATA_DIR:-$HOME/.config/agent-zero}"
    A0_APP="@appdir@"

    mkdir -p "$A0_DATA"

    # Symlink read-only application directories
    for item in python webui prompts lib docker docs tests; do
      target="$A0_DATA/$item"
      if [ -L "$target" ]; then
        # Re-create symlink in case the store path changed (e.g., after upgrade)
        rm "$target"
        ln -s "$A0_APP/$item" "$target"
      elif [ ! -e "$target" ]; then
        ln -s "$A0_APP/$item" "$target"
      fi
    done

    # Symlink read-only top-level files (.py, .json, .md)
    for item in "$A0_APP"/*.py "$A0_APP"/*.json "$A0_APP"/*.md; do
      [ -f "$item" ] || continue
      fname=$(basename "$item")
      target="$A0_DATA/$fname"
      if [ -L "$target" ]; then
        rm "$target"
        ln -s "$item" "$target"
      elif [ ! -e "$target" ]; then
        ln -s "$item" "$target"
      fi
    done

    # Ensure mutable directories exist (copy defaults on first run)
    for dir in usr logs tmp knowledge agents conf skills; do
      if [ ! -d "$A0_DATA/$dir" ]; then
        if [ -d "$A0_APP/$dir" ]; then
          cp -r "$A0_APP/$dir" "$A0_DATA/$dir"
          chmod -R u+w "$A0_DATA/$dir"
        else
          mkdir -p "$A0_DATA/$dir"
        fi
      fi
    done

    # Create .env if missing
    if [ ! -f "$A0_DATA/.env" ]; then
      touch "$A0_DATA/.env"
    fi

    cd "$A0_DATA"
    export AGENT_ZERO_HOME="$A0_DATA"

    # Trap SIGTRAP to prevent unclean exit during async client cleanup on macOS
    trap "" TRAP

    exec @pythonEnv@/bin/python @appdir@/nix_bootstrap.py "$@"
    EOF

    chmod +x $out/bin/agent-zero
    substituteInPlace $out/bin/agent-zero \
      --replace-fail "@appdir@" "$appdir" \
      --replace-fail "@pythonEnv@" "${pythonEnv}"

    # Setup script for manual first-time init / diagnostics
    cat > $out/bin/agent-zero-setup << 'SETUP_EOF'
    #!/usr/bin/env bash
    set -euo pipefail

    A0_DATA="''${AGENT_ZERO_DATA_DIR:-$HOME/.config/agent-zero}"
    A0_APP="@appdir@"

    echo "Agent Zero v@version@"
    echo "App source: $A0_APP"
    echo "Data dir:   $A0_DATA"
    echo ""

    mkdir -p "$A0_DATA"

    for dir in usr logs tmp knowledge agents conf skills; do
      if [ ! -d "$A0_DATA/$dir" ]; then
        if [ -d "$A0_APP/$dir" ]; then
          echo "Copying $dir/ (first-time setup)..."
          cp -r "$A0_APP/$dir" "$A0_DATA/$dir"
          chmod -R u+w "$A0_DATA/$dir"
        else
          echo "Creating $dir/..."
          mkdir -p "$A0_DATA/$dir"
        fi
      else
        echo "$dir/ already exists, skipping."
      fi
    done

    if [ ! -f "$A0_DATA/.env" ]; then
      touch "$A0_DATA/.env"
      echo "Created empty .env"
    else
      echo ".env already exists, skipping."
    fi

    echo ""
    echo "Setup complete. Run 'agent-zero' to start the web UI."
    SETUP_EOF

    chmod +x $out/bin/agent-zero-setup
    substituteInPlace $out/bin/agent-zero-setup \
      --replace-fail "@appdir@" "$appdir" \
      --replace-fail "@version@" "${version}"

    # Wrap both scripts with runtime dependencies on PATH
    for bin in $out/bin/agent-zero $out/bin/agent-zero-setup; do
      wrapProgram "$bin" \
        --prefix PATH : ${lib.makeBinPath [
          ffmpeg tesseract poppler-utils git openssh
        ]} \
        --set PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.browsers}" \
        --set TOKENIZERS_PARALLELISM "false" \
        --set PYTORCH_ENABLE_MPS_FALLBACK "1"
    done

    runHook postInstall
  '';

  meta = {
    description = "Agent Zero AI framework - personal organic agentic framework";
    homepage = "https://agent-zero.ai";
    changelog = "https://github.com/agent0ai/agent-zero/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "agent-zero";
    platforms = with lib.platforms; linux ++ darwin;
  };
}
