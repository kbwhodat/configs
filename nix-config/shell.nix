{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  # Directory where the virtual environment will be created.
  # venvDir = ".venv";

  buildInputs = [
    pkgs.python311Packages.python
    pkgs.python311Packages.venvShellHook
    # Add any Python packages you want pre-installed (they will be available in your venv)
    pkgs.python311Packages.requests
  ];

  # (Optional) After the venv is created, install packages from your requirements file.
  # postVenvCreation = ''
  #   echo "Installing requirements..."
  #   pip install -r requirements.txt
  # '';

  # Automatically source (activate) the venv when you enter the shell.
  postShellHook = ''
    echo "Activating virtual environment..."
    source .venv/bin/activate
  '';
}
