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
            # Elm dependencies
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-live
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.nodejs
            pkgs.uglify-js # For optimizing the JS
          ];

          shellHook = ''
            echo "Y2K Retro WebGL Portfolio Development Environment"
            echo "Run 'reset-env' to clean all Elm files and caches"
            echo "Run 'start-dev-offline' to start the Elm development server in offline mode"

            # Reset environment function
            reset-env() {
              echo "Resetting Elm environment..."

              # Remove project-specific generated files
              rm -rf elm-stuff
              rm -f elm.js elm.min.js

              # Optionally clean Elm home directory
              read -p "Clean ~/.elm directory? This will remove all installed packages. (y/N) " confirm
              if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                rm -rf ~/.elm
                echo "~/.elm directory removed"
              fi

              echo "Environment reset complete."
            }

            # Start development server in offline mode
            start-dev-offline() {
              echo "Starting Elm development server in offline mode..."
              elm make src/Main.elm --output=elm.js --offline
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js --offline
            }

            # Standard development server
            start-dev() {
              elm make src/Main.elm --output=elm.js
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
            }

            # Development server with debug in offline mode
            start-dev-debug-offline() {
              echo "Starting with debug output in offline mode..."
              elm make src/Main.elm --output=elm.js --debug --offline
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js --debug --offline
            }

            # Standard development server with debug
            start-dev-debug() {
              echo "Starting with debug output..."
              elm make src/Main.elm --output=elm.js --debug
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js --debug
            }

            # Production build in offline mode
            build-offline() {
              elm make src/Main.elm --optimize --output=elm.js --offline
              echo "Minifying..."
              uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output elm.min.js
            }

            # Standard production build
            build() {
              elm make src/Main.elm --optimize --output=elm.js
              echo "Minifying..."
              uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output elm.min.js
            }

            # Manually fix elm.json if HTTP is missing
            fix-elm-json() {
              if ! grep -q '"elm/http"' elm.json; then
                echo "Adding elm/http to elm.json..."
                cp elm.json elm.json.bak
                sed -i 's/"direct": {/"direct": {\n            "elm\/http": "2.0.0",/' elm.json
                echo "elm.json has been updated to include elm/http"
              else
                echo "elm/http is already in elm.json"
              fi
            }
          '';
        };
      }
    );
}
