defmodule Bitmex.WS do
  require Logger
  import Application, only: [get_env: 2]

  @behaviour :websocket_client

  @fsm_name {:local, __MODULE__}
  @base "wss://www.bitmex.com/realtime?heartbeat=true"
  @instrument get_env(:bitmex, :instrument) || "XBTUSD"
  @heartbeat_interval get_env(:bitmex, :heartbeat_interval) || 7_000

  ## API

  def start_link do
    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(@fsm_name, @base, __MODULE__, [], [])
  end

  def send_op(server \\ __MODULE__, op, args) do
    :websocket_client.send(server, {:text, encode(op, args)} |> IO.inspect)
  end

  def cast_op(server \\ __MODULE__, op, args) do
    :websocket_client.cast(server, {:text, encode(op, args)} |> IO.inspect)
  end

  def subscribe(server \\ __MODULE__) do
    cast_op(server, "subscribe", ["orderBook10:#{@instrument}"])
  end

  ## Callbacks

  def init([]) do
    {:once, %{}}
  end

  def onconnect(_ws_req, state) do
    Logger.info("Bitmex.WS connected")
    subscribe(self())
    {:ok, state, @heartbeat_interval}
  end

  def ondisconnect(:normal, state) do
    Logger.info("Bitmex.WS disconnected with reason :normal")
    {:ok, state}
  end

  def ondisconnect(reason, state) do
    Logger.warn("Bitmex.WS disconnected with #{inspect reason}. Reconnecting")
    {:reconnect, state}
  end

  def websocket_handle({:pong, _}, _conn_state, state) do
    {:ok, state}
  end

  def websocket_handle(msg, _conn_state, state) do
    info =
      with {:text, text} <- msg,
           {:ok, info} = Poison.Parser.parse(text),
           do: info
    Logger.info("Bitmex.WS received msg: #{inspect info}")
    {:ok, state}
  end

  def websocket_info(msg, _conn_state, state) do
    Logger.warn("Bitmex.WS received unexpected erlang msg: #{inspect msg}")
    {:ok, state}
  end

  def websocket_terminate(reason, _conn_state, state) do
    Logger.warn("Bitmex.WS closed in #{inspect state} with #{inspect reason}")
    :ok
  end

  defp encode(op, args) do
    %{op: op, args: args} |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
  end
end
