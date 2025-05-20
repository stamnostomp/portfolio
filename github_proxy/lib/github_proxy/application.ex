defmodule GithubProxy.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: GithubProxy.Router, options: [port: 3000]},
      {GithubProxy.Cache, name: GithubProxy.Cache}
    ]

    opts = [strategy: :one_for_one, name: GithubProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
