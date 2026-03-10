{ lib, writeShellApplication, uv }:

writeShellApplication {
  name = "jcodemunch";
  runtimeInputs = [ uv ];
  text = ''
    exec uvx --from jcodemunch-mcp jcodemunch-mcp "$@"
  '';

  meta = with lib; {
    description = "jCodeMunch MCP launcher";
    homepage = "https://github.com/jgravelle/jcodemunch-mcp";
    license = licenses.unfree;
    mainProgram = "jcodemunch";
  };
}
