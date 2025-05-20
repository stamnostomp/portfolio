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
