defmodule Leaderboard.MixProject do
  use Mix.Project

  def project do
    [
      app: :leaderboard,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        leaderboard: [
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Leaderboard.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
