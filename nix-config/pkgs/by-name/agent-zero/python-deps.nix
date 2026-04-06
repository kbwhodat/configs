# Custom Python package derivations for agent-zero dependencies
# not available in nixpkgs.
{ lib, stdenv, python313Packages, fetchPypi }:

let
  inherit (python313Packages) buildPythonPackage;

  # --- Zero-dependency packages ---

  uuid7 = buildPythonPackage rec {
    pname = "uuid7";
    version = "0.1.0";
    format = "wheel";
    src = fetchPypi {
      inherit pname version;
      format = "wheel";
      dist = "py2.py3";
      python = "py2.py3";
      hash = "sha256-XiWbtjyMtK3tWSf/QbREqA0McSTooM7Xz0TvofXMz2E=";
    };
    doCheck = false;
    meta = {
      description = "UUID version 7 - time-sortable UUIDs";
      homepage = "https://github.com/stevesimmons/uuid7";
      license = lib.licenses.unlicense;
    };
  };

  ansio = buildPythonPackage rec {
    pname = "ansio";
    version = "0.0.1";
    format = "wheel";
    src = fetchPypi {
      inherit pname version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-L1A9vx3yk15K+FtTwjT+drBL5RJcsCcOiCQ0vzt4mXw=";
    };
    doCheck = false;
    meta = {
      description = "ANSI input & output module";
      homepage = "https://pypi.org/project/ansio/";
      license = lib.licenses.mit;
    };
  };

  inputimeout = buildPythonPackage rec {
    pname = "inputimeout";
    version = "1.0.4";
    format = "wheel";
    src = fetchPypi {
      inherit pname version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-9OI9J3U8/CUmju/I1So+3EYoCtgx0iZhfFGIJCNHWkM=";
    };
    doCheck = false;
    meta = {
      description = "Multi-platform standard input with timeout";
      homepage = "https://pypi.org/project/inputimeout/";
      license = lib.licenses.mit;
    };
  };

  # --- Packages with simple deps (all in nixpkgs) ---

  flask-basicauth = buildPythonPackage rec {
    pname = "Flask-BasicAuth";
    version = "0.2.0";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-3169SJ3AkUwiRBnaBZ2ZHrcpiKAc3UuVbVKTLOfVAf8=";
    };
    build-system = [ python313Packages.setuptools ];
    dependencies = [ python313Packages.flask ];
    doCheck = false;
    meta = {
      description = "HTTP basic access authentication for Flask";
      homepage = "https://github.com/jpvanhal/flask-basicauth";
      license = lib.licenses.bsd3;
    };
  };

  fasta2a = buildPythonPackage rec {
    pname = "fasta2a";
    version = "0.6.0";
    format = "wheel";
    src = fetchPypi {
      inherit pname version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-I9STB/ajcuB7nsmiEYeghkQpFF6N7UpBJivTPi7K7kw=";
    };
    dependencies = with python313Packages; [
      pydantic
      starlette
      opentelemetry-api
    ];
    doCheck = false;
    meta = {
      description = "Convert an AI Agent into an A2A server";
      homepage = "https://pypi.org/project/fasta2a/";
      license = lib.licenses.mit;
    };
  };

  flaredantic = buildPythonPackage rec {
    pname = "flaredantic";
    version = "0.1.5";
    format = "wheel";
    src = fetchPypi {
      inherit pname version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-VdNO/pxCU7PE9eqCuHiNI/lWq05L8uSPBRr9tH7+qAA=";
    };
    dependencies = with python313Packages; [
      requests
      tqdm
    ];
    doCheck = false;
    meta = {
      description = "Create Cloudflare, Serveo, and Microsoft tunnels";
      homepage = "https://pypi.org/project/flaredantic/";
      license = lib.licenses.mit;
    };
  };

  langchain-unstructured = buildPythonPackage rec {
    pname = "langchain-unstructured";
    version = "1.0.1";
    format = "wheel";
    src = fetchPypi {
      pname = "langchain_unstructured";
      inherit version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-HNsAs7zMBdqm8DvDmRsKdicP0vwJWzWMI70IxfDgX1A=";
    };
    dependencies = with python313Packages; [
      langchain-core
      unstructured-client
    ];
    doCheck = false;
    meta = {
      description = "LangChain integration with Unstructured";
      homepage = "https://pypi.org/project/langchain-unstructured/";
      license = lib.licenses.mit;
    };
  };

  # --- Transitive deps of browser-use ---

  markdown-pdf = buildPythonPackage rec {
    pname = "markdown-pdf";
    version = "1.5";
    format = "wheel";
    src = fetchPypi {
      pname = "markdown_pdf";
      inherit version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-YXGv9ObFa85nmsFp/kPOJh/TRrfqUyCYCDn/2qiNNzU=";
    };
    dependencies = with python313Packages; [
      pymupdf
      markdown-it-py
      requests
      plantuml
      six
    ];
    doCheck = false;
    meta = {
      description = "Markdown to PDF renderer";
      homepage = "https://pypi.org/project/markdown-pdf/";
      license = lib.licenses.mit;
    };
  };

  bubus = buildPythonPackage rec {
    pname = "bubus";
    version = "1.4.7";
    format = "wheel";
    src = fetchPypi {
      inherit pname version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-ywAqmzrkc1oZY2Fm+yn2IYktxh3N1UzeYnFybBSMebw=";
    };
    dependencies = with python313Packages; [
      aiofiles
      anyio
      portalocker
      pydantic
      typing-extensions
      uuid7
    ];
    doCheck = false;
    meta = {
      description = "Advanced Pydantic-powered event bus with async support";
      homepage = "https://pypi.org/project/bubus/";
      license = lib.licenses.mit;
    };
  };

  patchright = buildPythonPackage rec {
    pname = "patchright";
    version = "1.52.5";
    format = "wheel";
    src =
      let
        srcs = {
          "x86_64-linux" = fetchPypi {
            inherit pname version;
            format = "wheel";
            dist = "py3";
            python = "py3";
            platform = "manylinux1_x86_64";
            hash = "sha256-9T9ueb776370LQCvQnaKZ2u7aNVnSvgkrl+y6fDjOew=";
          };
          "aarch64-darwin" = fetchPypi {
            inherit pname version;
            format = "wheel";
            dist = "py3";
            python = "py3";
            platform = "macosx_11_0_arm64";
            hash = "sha256-2GJDa6VAHeQmOuren7LZQh8KsUQqZ57/LYmV+XNoKwY=";
          };
          "x86_64-darwin" = fetchPypi {
            inherit pname version;
            format = "wheel";
            dist = "py3";
            python = "py3";
            platform = "macosx_10_13_x86_64";
            hash = "sha256-LY13VbVWcbRQ5BU/C6oAveLPmo7bQngsi0H0NweXUxQ=";
          };
        };
      in
        srcs.${stdenv.hostPlatform.system}
          or (throw "patchright: unsupported platform ${stdenv.hostPlatform.system}");
    dependencies = with python313Packages; [
      pyee
      greenlet
    ];
    doCheck = false;
    meta = {
      description = "Undetected version of the Playwright testing and automation library";
      homepage = "https://github.com/AdiAK104/patchright-python";
      license = lib.licenses.asl20;
      platforms = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    };
  };

  # --- The big one ---

  browser-use = buildPythonPackage rec {
    pname = "browser-use";
    version = "0.5.11";
    format = "wheel";
    src = fetchPypi {
      pname = "browser_use";
      inherit version;
      format = "wheel";
      dist = "py3";
      python = "py3";
      hash = "sha256-afZLIttAemApRjmswtn/iZcWL1dWQ+uVOxnPO0jrn18=";
    };
    dependencies = with python313Packages; [
      aiofiles
      anthropic
      anyio
      authlib
      bubus
      google-api-core
      google-api-python-client
      google-auth
      google-auth-oauthlib
      google-genai
      groq
      httpx
      markdown-pdf
      markdownify
      mcp
      ollama
      openai
      patchright
      playwright
      portalocker
      posthog
      psutil
      pydantic
      pypdf
      pyperclip
      python-dotenv
      requests
      screeninfo
      typing-extensions
      uuid7
    ];
    # Note: browser-use optionally depends on pyobjc on macOS for native
    # screen/clipboard integration. pyobjc is not in nixpkgs, so we skip it.
    # The browser agent works without it (uses playwright for browser control).
    doCheck = false;
    meta = {
      description = "Make websites accessible for AI agents";
      homepage = "https://github.com/browser-use/browser-use";
      license = lib.licenses.mit;
      platforms = with lib.platforms; linux ++ darwin;
    };
  };

in {
  inherit
    uuid7
    ansio
    inputimeout
    flask-basicauth
    fasta2a
    flaredantic
    langchain-unstructured
    markdown-pdf
    bubus
    patchright
    browser-use
    ;
}
