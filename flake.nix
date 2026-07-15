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

        # Real executables (not bash functions) so they work from any shell,
        # including fish.
        startDev = pkgs.writeShellScriptBin "start-dev" ''
          elm make src/Main.elm --output=elm.js
          elm-live src/Main.elm --start-page=index.html --hot --proxy-prefix=/api --proxy-host=http://localhost:4000/api -- --output=elm.js
        '';

        startBackend = pkgs.writeShellScriptBin "start-backend" ''
          # Load SMTP/contact-form secrets; docker-compose reads .env itself,
          # but a local mix run does not.
          if [ -f .env ]; then
            set -a
            . ./.env
            set +a
          fi
          cd backend && mix deps.get && mix run --no-halt
        '';

        generateElmNix = pkgs.writeShellScriptBin "generate-elm-nix" ''
          echo "Generating elm-srcs.nix..."
          elm2nix convert > elm-srcs.nix
          elm2nix snapshot
          echo "Generated elm-srcs.nix and registry.dat"
        '';

        generateBlogData = pkgs.writeShellScriptBin "generate-blog-data" ''
          echo "Generating blog/posts.json..."

          POSTS_DIR="blog/posts"
          OUTPUT_FILE="blog/posts.json"

          if [ ! -d "$POSTS_DIR" ]; then
              echo "Error: $POSTS_DIR not found"
              exit 1
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
        '';
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

            # Minify with mangle only. The Elm guide's --compress flags
            # (pure_funcs etc.) delete the discarded-result A2 calls that
            # elm-explorations/webgl uses to apply render settings, which
            # silently disables depth testing - do not re-add them.
            uglifyjs elm.js --mangle --output elm.min.js
          '';

          installPhase = ''
            mkdir -p $out
            cp index.html $out/ || true
            cp favicon.svg $out/ || true
            cp -r blog $out/ || true
            cp -r sfx $out/ || true
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

            # Elixir leaderboard backend
            pkgs.beamPackages.elixir
            pkgs.elixir-ls

            # Essential networking tools
            pkgs.cacert
            pkgs.curl
            pkgs.openssl

            # Dev commands (real binaries, so they work from fish too)
            startDev
            startBackend
            generateBlogData
            generateElmNix
          ];

          shellHook = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export CURL_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export REQUESTS_CA_BUNDLE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

            echo "Available commands:"
            echo "  start-dev          - Start development server (proxies /api to :4000)"
            echo "  start-backend      - Start the Elixir leaderboard backend on :4000"
            echo "  generate-blog-data - Generate posts.json from .org files"
            echo "  generate-elm-nix   - Generate elm-srcs.nix for Nix builds"
          '';
        };
      }
    );
}
