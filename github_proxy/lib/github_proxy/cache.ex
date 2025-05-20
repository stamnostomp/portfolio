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
