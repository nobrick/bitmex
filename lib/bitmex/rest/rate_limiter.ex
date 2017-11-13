defmodule Bitmex.Rest.RateLimiter do
  use GenServer

  @max_rate_limit 300

  ## API

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def set_rate(server \\ __MODULE__, headers) do
    GenServer.call(server, {:set_rate, headers})
  end

  def rate(server \\ __MODULE__) do
    GenServer.call(server, :rate)
  end

  def remaining(server \\ __MODULE__) do
    GenServer.call(server, :remaining)
  end

  ## Callbacks
  #
  @impl true
  def init(_) do
    {:ok, %{rate: %{limit: @max_rate_limit, remaining: @max_rate_limit,
                    reset: nil}}}
  end

  @impl true
  def handle_call({:set_rate, headers}, _from, _state) do
    rate = %{limit:     parse_to_int(headers, "X-RateLimit-Limit"),
             remaining: parse_to_int(headers, "X-RateLimit-Remaining"),
             reset:     parse_to_int(headers, "X-RateLimit-Reset")}
    {:reply, :ok, %{rate: rate}}
  end

  @impl true
  def handle_call(:rate, _from, %{rate: rate} = state) do
    {:reply, rate, state}
  end

  @impl true
  def handle_call(:remaining, _from,
                  %{rate: %{remaining: remaining}} = state) do
    {:reply, remaining, state}
  end

  ## Helpers

  defp parse_to_int(headers, key) do
    headers
    |> Enum.find(fn {k, _v} -> k == key end)
    |> elem(1)
    |> String.to_integer
  end
end
