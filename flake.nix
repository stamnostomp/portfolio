# flake.nix - Fixed version with SSL certificates
{
  description = "Y2K Retro WebGL Portfolio with Elm - SSL Fixed";

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
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Elm dependencies
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-live
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.uglify-js

            # Essential networking tools
            pkgs.cacert
            pkgs.curl
            pkgs.openssl
          ];

          shellHook = ''
                        # CRITICAL: Fix SSL certificates for Elm networking
                        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export CURL_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

                        # Additional SSL environment variables for some tools
                        export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

                        echo "🔒 SSL certificates configured"
                        echo "📦 Certificate bundle: $SSL_CERT_FILE"
                        echo ""

                        # Test connectivity
                        echo "🌐 Testing connectivity to Elm package registry..."
                        if curl -s --max-time 5 https://package.elm-lang.org/all-packages > /dev/null; then
                            echo "✅ Elm package registry reachable"
                        else
                            echo "❌ Cannot reach Elm package registry"
                            echo "   This might be a firewall or network issue"
                        fi
                        echo ""

                        echo "🎯 Y2K Retro WebGL Portfolio Development Environment"
                        echo "Available commands:"
                        echo "  test-networking  - Run network diagnostics"
                        echo "  setup-elm       - Create basic Elm project"
                        echo "  start-dev       - Start development server"
                        echo "  manual-elm      - Create elm.json manually (offline)"

                        # Network testing function
                        test-networking() {
                            echo "🔍 Running network diagnostics..."
                            echo "SSL_CERT_FILE: $SSL_CERT_FILE"
                            echo "Testing HTTPS connection:"
                            curl -v --max-time 10 https://package.elm-lang.org/all-packages 2>&1 | head -15
                        }

                        # Setup Elm project
                        setup-elm() {
                            echo "🛠️  Setting up Elm project..."
                            mkdir -p src

                            # Try elm init first
                            if elm init; then
                                echo "✅ elm init successful!"
                            else
                                echo "❌ elm init failed, creating manually..."
                                manual-elm
                            fi
                        }

                        # Manual elm.json creation
                        manual-elm() {
                            echo "📝 Creating elm.json manually..."
                            cat > elm.json << 'ELMJSON'
            {
                "type": "application",
                "source-directories": ["src"],
                "elm-version": "0.19.1",
                "dependencies": {
                    "direct": {
                        "elm/browser": "1.0.2",
                        "elm/core": "1.0.5",
                        "elm/html": "1.0.0",
                        "elm/json": "1.1.3",
                        "elm/time": "1.0.0"
                    },
                    "indirect": {
                        "elm/url": "1.0.0",
                        "elm/virtual-dom": "1.0.3"
                    }
                },
                "test-dependencies": {"direct": {}, "indirect": {}}
            }
            ELMJSON

                            mkdir -p src

                            # Create basic Main.elm if it doesn't exist
                            if [ ! -f "src/Main.elm" ]; then
                                cat > src/Main.elm << 'MAINELM'
            module Main exposing (main)

            import Browser
            import Html exposing (..)
            import Html.Attributes exposing (..)

            type alias Model = {}
            type Msg = NoOp

            init : () -> ( Model, Cmd Msg )
            init _ = ( {}, Cmd.none )

            update : Msg -> Model -> ( Model, Cmd Msg )
            update msg model = ( model, Cmd.none )

            view : Model -> Html Msg
            view model =
                div [ style "padding" "20px", style "font-family" "monospace" ]
                    [ h1 [] [ text "🌊 Elm + Nix Working!" ]
                    , p [] [ text "Ready to add goop ball navigation..." ]
                    ]

            main : Program () Model Msg
            main =
                Browser.element
                    { init = init
                    , view = view
                    , update = update
                    , subscriptions = \_ -> Sub.none
                    }
            MAINELM
                            fi

                            echo "✅ Created elm.json and basic Main.elm manually"
                            echo "🚀 Try: elm make src/Main.elm --output=elm.js"
                        }

                        start-dev() {
                            if [ ! -f "elm.json" ]; then
                                echo "No elm.json found. Setting up project first..."
                                setup-elm
                            fi

                            echo "🚀 Starting development server..."
                            elm make src/Main.elm --output=elm.js
                            elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
                        }

                        # Export functions to be available in the shell
                        export -f test-networking
                        export -f setup-elm
                        export -f manual-elm
                        export -f start-dev
          '';
        };
      }
    );
}
