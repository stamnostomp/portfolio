defmodule Leaderboard.Store do
  @moduledoc """
  Score storage in a plain JSON file (DATA_DIR/scores.json), so scores
  survive restarts and the file can be inspected or edited by hand.

  All access is serialized through this GenServer. Writes go to a temp
  file followed by a rename, so a crash mid-write can't corrupt the file.
  """

  use GenServer

  @top_n 10
  @max_entries_per_game 100

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc "Top #{@top_n} entries for a game, best first."
  def top(game), do: GenServer.call(__MODULE__, {:top, game})

  @doc "Record a score and return the updated top entries."
  def submit(game, name, score), do: GenServer.call(__MODULE__, {:submit, game, name, score})

  # The state is a map of game slug => sorted list of entry maps
  # (%{"name" => ..., "score" => ..., "at" => ...}).

  @impl true
  def init(nil) do
    {:ok, load()}
  end

  @impl true
  def handle_call({:top, game}, _from, scores) do
    {:reply, top_entries(scores, game), scores}
  end

  def handle_call({:submit, game, name, score}, _from, scores) do
    entry = %{"name" => name, "score" => score, "at" => System.system_time(:second)}

    entries =
      [entry | Map.get(scores, game, [])]
      |> sort_entries()
      |> Enum.take(@max_entries_per_game)

    scores = Map.put(scores, game, entries)
    persist(scores)
    {:reply, top_entries(scores, game), scores}
  end

  defp top_entries(scores, game) do
    scores |> Map.get(game, []) |> Enum.take(@top_n)
  end

  # Highest score first; ties go to whoever got there first.
  defp sort_entries(entries) do
    Enum.sort_by(entries, &{-&1["score"], &1["at"]})
  end

  defp load do
    with {:ok, body} <- File.read(file_path()),
         {:ok, %{} = scores} <- Jason.decode(body) do
      Map.new(scores, fn {game, entries} ->
        {game, entries |> List.wrap() |> Enum.filter(&valid?/1) |> Enum.map(&normalize/1) |> sort_entries()}
      end)
    else
      _ -> %{}
    end
  end

  defp valid?(%{"name" => name, "score" => score}) when is_binary(name) and is_integer(score),
    do: true

  defp valid?(_entry), do: false

  # Hand-added entries may omit the timestamp.
  defp normalize(entry), do: Map.put_new(entry, "at", 0)

  defp persist(scores) do
    path = file_path()
    File.mkdir_p!(Path.dirname(path))
    tmp = path <> ".tmp"
    File.write!(tmp, Jason.encode!(scores, pretty: true))
    File.rename!(tmp, path)
  end

  defp file_path do
    Path.join(System.get_env("DATA_DIR", "data"), "scores.json")
  end
end
