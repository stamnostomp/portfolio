# flake.nix
{
  description = "Y2K Retro WebGL Portfolio with Elm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-live
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.nodejs
            pkgs.uglify-js # For optimizing the JS
          ];

          shellHook = ''
            echo "Y2K Retro WebGL Portfolio Development Environment"
            echo "Run 'setup-project' to install required Elm packages"
            echo "Run 'start-dev' to start the development server"

            setup-project() {
              mkdir -p src
              cd src
              elm init
              elm install elm/core
              elm install elm/html
              elm install elm/browser
              elm install elm/json
              elm install elm/time
              elm install elm-explorations/webgl
              elm install elm-explorations/linear-algebra
              cd ..
            }

            start-dev() {
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
            }

            build() {
              elm make src/Main.elm --optimize --output=elm.js
              echo "Minifying..."
              uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output elm.min.js
            }
          '';
        };
      }
    );
}
