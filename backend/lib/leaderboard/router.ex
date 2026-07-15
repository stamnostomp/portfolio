defmodule Leaderboard.Router do
  use Plug.Router

  # Slugs the frontend is allowed to store scores under.
  @games ~w(rat-snatcher missile-command shooter)

  @max_name_length 16
  @max_score 1_000_000_000

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/api/health" do
    send_json(conn, 200, %{status: "ok"})
  end

  get "/api/leaderboard/:game" do
    case validate_game(game) do
      :ok -> send_json(conn, 200, Leaderboard.Store.top(game))
      {:error, status, message} -> send_json(conn, status, %{error: message})
    end
  end

  post "/api/leaderboard/:game" do
    with :ok <- validate_game(game),
         {:ok, name, score} <- validate_entry(conn.body_params) do
      send_json(conn, 201, Leaderboard.Store.submit(game, name, score))
    else
      {:error, status, message} -> send_json(conn, status, %{error: message})
    end
  end

  match _ do
    send_json(conn, 404, %{error: "not found"})
  end

  defp validate_game(game) when game in @games, do: :ok
  defp validate_game(_game), do: {:error, 404, "unknown game"}

  defp validate_entry(%{"name" => name, "score" => score})
       when is_binary(name) and is_integer(score) do
    name = name |> String.trim() |> String.slice(0, @max_name_length)

    cond do
      name == "" -> {:error, 422, "name must not be empty"}
      score < 0 or score > @max_score -> {:error, 422, "score out of range"}
      true -> {:ok, name, score}
    end
  end

  defp validate_entry(_params) do
    {:error, 422, ~s(expected {"name": string, "score": integer})}
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
