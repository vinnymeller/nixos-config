{
    description = "QTile config flake with lsp support";

    inputs.flake-utils.url = "github:numtide/flake-utils";

    outputs = { self, nixpkgs, flake-utils }:
        flake-utils.lib.eachDefaultSystem
            (system:
                let pkgs = nixpkgs.legacyPackages.${system}; in
                {
                    devShells.default = pkgs.mkShell rec {
                        name = "impurePythonEnv";
                        venvDir = "./.venv";
                        buildInputs = with pkgs; [
                            python3Packages.python
                            python3Packages.venvShellHook
                            taglib
                            openssl
                            git
                            libxml2
                            libxslt
                            libzip
                            zlib
                            ];

                        postVenvCreation = ''
                            unset SOURCE_DATE_EPOCH
                            pip install -r requirements.txt
                        '';

                        postShellHook = ''
                            unset SOURCE_DATE_EPOCH
                        '';
                    };
                }
            );

}
