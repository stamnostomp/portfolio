defmodule GithubProxy.Router do
  use Plug.Router

  plug Plug.Logger
  plug CORSPlug, origin: ["http://localhost:8000"]
  plug :match
  plug :dispatch
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason

  # Configuration
  @github_username "stamnostomp"
  # @github_token nil  # Optional: your GitHub token

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

  # Build headers for GitHub API requests
  defp build_headers do
    headers = [{"Accept", "application/vnd.github.v3+json"}]

    # Add token if configured
    # if @github_token do
    #   [{"Authorization", "token #{@github_token}"} | headers]
    # else
    #   headers
    # end

    headers
  end
end
