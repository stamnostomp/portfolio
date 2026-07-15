defmodule Leaderboard.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT", "4000"))

    children = [
      Leaderboard.Store,
      {Bandit, plug: Leaderboard.Router, port: port}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Leaderboard.Supervisor)
  end
end
