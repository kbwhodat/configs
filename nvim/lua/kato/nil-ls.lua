require'lspconfig'.nil_ls.setup{
    settings = {
        ["nil"] = {
            formatting = {
                command = {"nixpkgs-fmt"}  -- Change to `nil` if you do not wish to specify a formatter
            },
            diagnostics = {
                ignored = {"unused_binding", "unused_with"},
                excludedFiles = {"Cargo.nix"}
            },
            nix = {
                binary = "/run/current-system/sw/bin/nix",
                maxMemoryMB = 2560,
                flake = {
                    autoArchive = true,
                    autoEvalInputs = false,
                    nixpkgsInputName = "nixpkgs"
                }
            }
        }
    }
}
