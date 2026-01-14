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
        packages.default = pkgs.stdenv.mkDerivation {
          name = "portfolio";
          src = ./.;

          nativeBuildInputs = [
            pkgs.elmPackages.elm
            pkgs.uglify-js
          ];

          configurePhase = pkgs.elmPackages.fetchElmDeps {
            elmPackages = import ./elm-srcs.nix;
            elmVersion = "0.19.1";
            registryDat = ./registry.dat;
          };

          buildPhase = ''
            # Compile Elm to JavaScript
            elm make src/Main.elm --optimize --output=elm.js

            # Minify the output
            uglifyjs elm.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output elm.min.js
          '';

          installPhase = ''
            mkdir -p $out
            cp index.html $out/ || true
            cp -r blog $out/ || true
            cp elm.min.js $out/elm.js
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Elm dependencies
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-live
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.uglify-js
            pkgs.elm2nix

            # Essential networking tools
            pkgs.cacert
            pkgs.curl
            pkgs.openssl
          ];

          shellHook = ''
                        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export CURL_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                        export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

                        echo "Available commands:"
                        echo "  start-dev          - Start development server"
                        echo "  generate-blog-data - Generate posts.json from .org files"
                        echo "  generate-elm-nix   - Generate elm-srcs.nix for Nix builds"

                        start-dev() {
                            elm make src/Main.elm --output=elm.js
                            elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
                        }

                        generate-blog-data() {
                            echo "Generating blog/posts.json..."

                            POSTS_DIR="blog/posts"
                            OUTPUT_FILE="blog/posts.json"

                            if [ ! -d "$POSTS_DIR" ]; then
                                echo "Error: $POSTS_DIR not found"
                                return 1
                            fi

                            echo "[" > "$OUTPUT_FILE"

                            first=true
                            for orgfile in "$POSTS_DIR"/*.org; do
                                [ -f "$orgfile" ] || continue

                                if [ "$first" = false ]; then
                                    echo "," >> "$OUTPUT_FILE"
                                fi
                                first=false

                                title=$(grep "^#+TITLE:" "$orgfile" | sed 's/^#+TITLE: *//' || echo "Untitled")
                                date=$(grep "^#+DATE:" "$orgfile" | sed 's/^#+DATE: *//' || echo "Unknown")
                                slug=$(basename "$orgfile" .org)
                                summary=$(grep "^#+SUMMARY:" "$orgfile" | sed 's/^#+SUMMARY: *//' || echo "")
                                tags=$(grep "^#+TAGS:" "$orgfile" | sed 's/^#+TAGS: *//' || echo "")
                                categories=$(grep "^#+CATEGORIES:" "$orgfile" | sed 's/^#+CATEGORIES: *//' || echo "")
                                author=$(grep "^#+AUTHOR:" "$orgfile" | sed 's/^#+AUTHOR: *//' || echo "")

                                tags_json=$(echo "$tags" | awk -F', *' '{for(i=1;i<=NF;i++) printf "\"%s\"%s", $i, (i<NF?",":"")}')
                                categories_json=$(echo "$categories" | awk -F', *' '{for(i=1;i<=NF;i++) printf "\"%s\"%s", $i, (i<NF?",":"")}')

                                cat >> "$OUTPUT_FILE" << EOF
  {
    "title": "$title",
    "date": "$date",
    "slug": "$slug",
    "summary": "$summary",
    "tags": [$tags_json],
    "categories": [$categories_json],
    "author": $(if [ -n "$author" ]; then echo "\"$author\""; else echo "null"; fi)
  }
EOF
                                echo "  $slug"
                            done

                            echo "" >> "$OUTPUT_FILE"
                            echo "]" >> "$OUTPUT_FILE"

                            echo "Generated $OUTPUT_FILE"
                        }

                        manual-elm() {
                            cat > elm.json << 'EOF'
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
EOF
                        }

                        generate-elm-nix() {
                            echo "Generating elm-srcs.nix..."
                            elm2nix convert > elm-srcs.nix
                            elm2nix snapshot
                            echo "Generated elm-srcs.nix and registry.dat"
                        }

                        export -f start-dev
                        export -f generate-blog-data
                        export -f generate-elm-nix
                        export -f manual-elm
          '';
        };
      }
    );
}
