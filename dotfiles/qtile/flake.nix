{
  description = "QTile config flake with lsp support";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      python-pkgs =
        pkgs.python3.withPackages (ps: with ps; [black mypy qtile]);
    in {
      devShells.default = pkgs.mkShell rec {
        name = "qtileDevEnv";
        packages = with pkgs; [python-pkgs qtile];
      };
    });
}
