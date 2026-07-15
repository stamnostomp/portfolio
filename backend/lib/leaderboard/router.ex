defmodule Leaderboard.Router do
  use Plug.Router

  # Slugs the frontend is allowed to store scores under.
  @games ~w(rat-snatcher missile-command shooter)

  @max_name_length 16
  @max_score 1_000_000_000

  @contact_max_name 100
  @contact_max_email 200
  @contact_max_message 5_000
  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

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

  post "/api/contact" do
    with {:ok, name, email, message} <- validate_contact(conn.body_params),
         :ok <- check_rate_limit(conn) do
      case Leaderboard.Mailer.send_contact(name, email, message) do
        :ok -> send_json(conn, 201, %{status: "sent"})
        {:error, :not_configured} -> send_json(conn, 503, %{error: "contact form is not configured"})
        {:error, :send_failed} -> send_json(conn, 502, %{error: "failed to send message"})
      end
    else
      # Filled honeypot: report success so bots have nothing to learn from.
      :honeypot -> send_json(conn, 201, %{status: "sent"})
      {:error, status, message} -> send_json(conn, status, %{error: message})
    end
  end

  match _ do
    send_json(conn, 404, %{error: "not found"})
  end

  defp validate_contact(%{"name" => name, "email" => email, "message" => message} = params)
       when is_binary(name) and is_binary(email) and is_binary(message) do
    name = String.trim(name)
    email = String.trim(email)
    message = String.trim(message)

    cond do
      Map.get(params, "website", "") != "" -> :honeypot
      name == "" or email == "" or message == "" -> {:error, 422, "all fields are required"}
      String.length(name) > @contact_max_name -> {:error, 422, "name too long"}
      String.length(email) > @contact_max_email -> {:error, 422, "email too long"}
      String.length(message) > @contact_max_message -> {:error, 422, "message too long"}
      not Regex.match?(@email_regex, email) -> {:error, 422, "invalid email address"}
      true -> {:ok, name, email, message}
    end
  end

  defp validate_contact(_params) do
    {:error, 422, ~s(expected {"name": string, "email": string, "message": string})}
  end

  defp check_rate_limit(conn) do
    # nginx sits in front and sets X-Real-IP; fall back to the peer address.
    ip =
      case get_req_header(conn, "x-real-ip") do
        [ip | _] -> ip
        [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
      end

    if Leaderboard.RateLimit.allow?({:contact, ip}) do
      :ok
    else
      {:error, 429, "too many messages, try again later"}
    end
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
