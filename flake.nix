# flake.nix
{
  description = "Y2K Retro WebGL Portfolio with Elm and Elixir GitHub Proxy";

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

            # Elixir dependencies for GitHub proxy
            pkgs.elixir
            pkgs.erlang
            pkgs.inotify-tools # For file watching in development
          ];

          shellHook = ''
            echo "Y2K Retro WebGL Portfolio Development Environment"
            echo "Run 'setup-elm' to install required Elm packages"
            echo "Run 'setup-proxy' to create the Elixir GitHub proxy"
            echo "Run 'start-dev' to start the Elm development server"
            echo "Run 'start-proxy' to start the GitHub proxy server"
            echo "Run 'stop-proxy' to stop a running GitHub proxy server"
            echo "Run 'restart-proxy' to restart the proxy server"
            echo "Run 'force-stop-proxy' to forcefully kill any stuck processes"
            echo "Run 'start-all' to start both servers together"

            # Elm setup functions
            setup-elm() {
              mkdir -p src
              cd src
              elm init || true
              elm install elm/core
              elm install elm/html
              elm install elm/browser
              elm install elm/json
              elm install elm/time
              elm install elm/http
              elm install elm-explorations/webgl
              elm install elm-explorations/linear-algebra
              cd ..
            }

            start-dev() {
              elm make src/Main.elm --output=elm.js
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
            }

            start-dev-debug() {
              echo "Starting with debug output..."
              elm make src/Main.elm --output=elm.js --debug
              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js --debug
            }

            build() {
              elm make src/Main.elm --optimize --output=elm.js
              echo "Minifying..."
              uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output elm.min.js
            }

            # GitHub Proxy setup functions
            setup-proxy() {
              # Create Elixir GitHub proxy project
              mkdir -p github_proxy
              cd github_proxy

              if [ ! -f "mix.exs" ]; then
                mix new . --sup --app github_proxy

                # Create necessary directories
                mkdir -p lib/github_proxy

                # Create application.ex
                cat > lib/github_proxy/application.ex << 'EOF'
defmodule GithubProxy.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: GithubProxy.Router, options: [port: 8001]},
      {GithubProxy.Cache, name: GithubProxy.Cache}
    ]

    opts = [strategy: :one_for_one, name: GithubProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
EOF

                # Create router.ex
                cat > lib/github_proxy/router.ex << 'EOF'
defmodule GithubProxy.Router do
  use Plug.Router

  plug Plug.Logger
  plug CORSPlug, origin: ["http://localhost:8000"]
  plug :match
  plug :dispatch
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason

  # Configuration - only your GitHub username is needed for public repos
  @github_username "stamnostomp"

  # No API token is required for public repositories!
  # GitHub allows 60 requests per hour without authentication, which is
  # typically sufficient for most users. Only add a token if you're
  # hitting rate limits or need access to private repositories.

  get "/api/all-commits" do
    # Check cache first
    case GithubProxy.Cache.get(:commits) do
      nil ->
        # Fetch fresh data if not in cache
        case fetch_all_commits() do
          {:ok, commits} ->
            # Cache results for 5 minutes
            GithubProxy.Cache.put(:commits, commits, 300)

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(commits))

          {:error, reason} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{error: reason}))
        end

      commits ->
        # Return cached data
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(commits))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  # Fetch all repositories for a user
  defp fetch_repositories do
    url = "https://api.github.com/users/#{@github_username}/repos"
    headers = build_headers()

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "GitHub API returned #{status_code}: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Error fetching repositories: #{reason}"}
    end
  end

  # Fetch commits for a specific repository
  defp fetch_commits(repo) do
    url = "https://api.github.com/repos/#{@github_username}/#{repo["name"]}/commits"
    headers = build_headers()

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        commits =
          body
          |> Jason.decode!()
          |> Enum.map(fn commit ->
            Map.put(commit, "repository", %{
              "name" => repo["name"],
              "url" => repo["html_url"]
            })
          end)

        {:ok, commits}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        # Just skip this repo if there's an error
        IO.puts("Error fetching commits for #{repo["name"]}: status #{status_code}")
        {:ok, []}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Error fetching commits for #{repo["name"]}: #{reason}")
        {:ok, []}
    end
  end

  # Fetch commits from all repositories
  defp fetch_all_commits do
    with {:ok, repos} <- fetch_repositories() do
      # Use tasks to fetch commits concurrently
      commits_tasks = Enum.map(repos, fn repo ->
        Task.async(fn -> fetch_commits(repo) end)
      end)

      # Wait for all tasks to complete
      commits_results = Task.await_many(commits_tasks, 30_000)

      # Combine all commits
      all_commits =
        commits_results
        |> Enum.filter(fn result -> match?({:ok, _}, result) end)
        |> Enum.flat_map(fn {:ok, commits} -> commits end)
        |> Enum.sort_by(fn commit ->
          get_in(commit, ["commit", "author", "date"])
        end, {:desc, Date})

      {:ok, all_commits}
    end
  end

  # Build headers for GitHub API requests - for public repos, just the Accept header is needed
  defp build_headers do
    [{"Accept", "application/vnd.github.v3+json"}]

    # Only add a token if you need higher rate limits or private repo access:
    # [{"Authorization", "token YOUR_TOKEN_HERE"} | headers]
  end
end
EOF

                # Create cache.ex
                cat > lib/github_proxy/cache.ex << 'EOF'
defmodule GithubProxy.Cache do
  use GenServer

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value, ttl \\ 300) do
    GenServer.cast(__MODULE__, {:put, key, value, ttl})
  end

  # Server API
  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case Map.get(state, key) do
      {value, expires_at} ->
        if :os.system_time(:second) < expires_at do
          {:reply, value, state}
        else
          {:reply, nil, Map.delete(state, key)}
        end
      nil ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_cast({:put, key, value, ttl}, state) do
    expires_at = :os.system_time(:second) + ttl
    {:noreply, Map.put(state, key, {value, expires_at})}
  end
end
EOF

                # Update mix.exs for dependencies
                cat > mix.exs << 'EOF'
defmodule GithubProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :github_proxy,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {GithubProxy.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:cors_plug, "~> 3.0"},
      {:jason, "~> 1.3"},
      {:httpoison, "~> 1.8"}
    ]
  end
end
EOF

                echo "GitHub proxy files created successfully."
              else
                echo "GitHub proxy project already exists."
              fi

              # Get dependencies
              mix deps.get

              echo "GitHub proxy setup complete. Use 'start-proxy' to run it."
              cd ..
            }

            start-proxy() {
              cd github_proxy
              echo "Starting GitHub proxy server on http://localhost:8001..."
              mix run --no-halt
            }

            # Stop the proxy server if it's running
            stop-proxy() {
              echo "Stopping any running GitHub proxy server..."
              pkill -f "mix run" || echo "No running proxy server found."
            }

            # Restart the proxy server (stop and start)
            restart-proxy() {
              stop-proxy
              sleep 1  # Allow a moment for the process to fully terminate
              start-proxy
            }

            # Force kill any stubborn Elixir/Beam processes
            force-stop-proxy() {
              echo "Forcefully stopping any Elixir/Beam processes..."
              pkill -9 -f "beam.smp" || echo "No Elixir processes found."
              pkill -9 -f "mix run" || echo "No Mix processes found."
            }

            # Allow running both servers concurrently with simple command
            start-all() {
              echo "Starting both Elm and GitHub proxy servers..."
              (cd github_proxy && mix run --no-halt) &
              PROXY_PID=$!
              trap "kill $PROXY_PID" EXIT

              elm-live src/Main.elm --start-page=index.html --hot -- --output=elm.js
            }

            # Update GitHub repository configuration
            update-github-username() {
              if [ -z "$1" ]; then
                echo "Usage: update-github-username <username>"
                return 1
              fi

              USERNAME="$1"
              cd github_proxy
              sed -i "s/@github_username \".*\"/@github_username \"$USERNAME\"/g" lib/github_proxy/router.ex
              echo "GitHub username updated to: $USERNAME"
              cd ..
            }
          '';
        };
      }
    );
}
