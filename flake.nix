# flake.nix
{
  description = "Y2K Retro WebGL Portfolio with Elm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
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
            pkgs.curl     # For downloading packages manually if needed
          ];

          shellHook = ''
            echo "Y2K Retro WebGL Portfolio Development Environment"
            echo "Run 'setup-project' to install required Elm packages"
            echo "Run 'fix-model-file' to correct the typo in Model.elm"
            echo "Run 'start-dev' to start the development server"

            # Fix the typo in Model.elm
            fix-model-file() {
              if [ -f src/Model.elm ]; then
                # Backup the original file
                cp src/Model.elm src/Model.elm.bak
                # Fix the typo (mmodule -> module)
                sed -i 's/^mmodule/module/' src/Model.elm
                echo "Fixed typo in Model.elm"
              else
                echo "Model.elm not found. Make sure you're in the project root."
              fi
            }

            # Setup project correctly at the root level
            setup-project() {
              echo "Setting up Elm project..."

              # Only initialize if elm.json doesn't exist
              if [ ! -f elm.json ]; then
                echo "Creating new elm.json..."
                elm init --yes
              fi

              # Ensure src directory exists
              mkdir -p src

              # Install required packages
              echo "Installing Elm packages..."

              # Try direct installation first
              if elm install elm/core elm/html elm/browser elm/json elm/time; then
                echo "Basic packages installed successfully."
              else
                echo "Warning: Couldn't install basic packages from registry."
              fi

              # Try WebGL packages - these often cause issues
              if elm install elm-explorations/webgl elm-explorations/linear-algebra; then
                echo "WebGL packages installed successfully."
              else
                echo "Warning: Couldn't install WebGL packages from registry."

                # Fallback: manual installation of WebGL packages
                echo "Attempting manual installation of WebGL packages..."

                # Create package directories
                mkdir -p ~/.elm/0.19.1/packages/elm-explorations/webgl/1.1.3/
                mkdir -p ~/.elm/0.19.1/packages/elm-explorations/linear-algebra/1.0.3/

                # Download from GitHub as fallback
                echo "Downloading WebGL package..."
                curl -L https://github.com/elm-explorations/webgl/archive/refs/tags/1.1.3.tar.gz -o /tmp/webgl.tar.gz
                tar -xzf /tmp/webgl.tar.gz -C /tmp
                cp -r /tmp/webgl-1.1.3/* ~/.elm/0.19.1/packages/elm-explorations/webgl/1.1.3/

                echo "Downloading Linear Algebra package..."
                curl -L https://github.com/elm-explorations/linear-algebra/archive/refs/tags/1.0.3.tar.gz -o /tmp/linear-algebra.tar.gz
                tar -xzf /tmp/linear-algebra.tar.gz -C /tmp
                cp -r /tmp/linear-algebra-1.0.3/* ~/.elm/0.19.1/packages/elm-explorations/linear-algebra/1.0.3/

                # Update elm.json manually to include these packages
                # This is a simplified approach - a more robust solution would parse and modify the JSON
                echo "Updating elm.json to include WebGL packages..."
                sed -i 's/"elm\/time": "1.0.0"/"elm\/time": "1.0.0",\n            "elm-explorations\/linear-algebra": "1.0.3",\n            "elm-explorations\/webgl": "1.1.3"/' elm.json
              fi

              # Verify elm.json is correct
              echo "Project setup complete. Verifying elm.json..."
              cat elm.json
            }

            # Start development server
            start-dev() {
              echo "Building Elm project..."
              elm make src/Main.elm --output=elm.js

              echo "Starting development server..."
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
            }

            # Start with debug output
            start-dev-debug() {
              echo "Starting with debug output..."
              elm make src/Main.elm --output=elm.js --debug
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js --debug
            }

            # Build for production
            build() {
              elm make src/Main.elm --optimize --output=elm.js
              echo "Minifying..."
              uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output elm.min.js
            }

            # Build in offline mode (useful if package server is unreachable)
            build-offline() {
              echo "Building in offline mode..."
              elm make src/Main.elm --output=elm.js --offline
            }

            # Function to verify file structure
            verify-structure() {
              echo "Verifying project structure..."

              # Check for critical files
              if [ ! -f elm.json ]; then
                echo "Error: elm.json not found in project root."
              else
                echo "✓ elm.json exists"
              fi

              if [ ! -f src/Main.elm ]; then
                echo "Warning: src/Main.elm not found. Create it if needed."
              else
                echo "✓ src/Main.elm exists"
              fi

              if [ ! -f index.html ]; then
                echo "Warning: index.html not found in project root."
              else
                echo "✓ index.html exists"
              fi

              # Check Model.elm for the typo
              if [ -f src/Model.elm ]; then
                if grep -q "^mmodule" src/Model.elm; then
                  echo "Error: Model.elm contains a typo. Run 'fix-model-file' to fix it."
                else
                  echo "✓ src/Model.elm looks good"
                fi
              fi

              echo "Structure verification complete."
            }
          '';
        };
      }
    );
}
