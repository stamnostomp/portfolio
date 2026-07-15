defmodule Leaderboard.RateLimit do
  @moduledoc """
  Tiny per-key sliding-window rate limiter backed by ETS. Used to keep the
  contact form from being turned into a spam cannon.
  """

  use GenServer

  @table __MODULE__
  @window_ms 10 * 60 * 1000
  @max_per_window 3

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(nil) do
    :ets.new(@table, [:named_table, :public, :bag])
    {:ok, nil}
  end

  @doc "Records a hit for `key` and returns whether it is still under the limit."
  def allow?(key) do
    now = System.monotonic_time(:millisecond)
    cutoff = now - @window_ms

    recent =
      for {^key, stamp} <- :ets.lookup(@table, key), stamp > cutoff, do: stamp

    :ets.delete(@table, key)

    if length(recent) >= @max_per_window do
      Enum.each(recent, &:ets.insert(@table, {key, &1}))
      false
    else
      Enum.each([now | recent], &:ets.insert(@table, {key, &1}))
      true
    end
  end
end
