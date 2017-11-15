defmodule Bitmex.Websocket.Parser do
  use GenServer
  require Logger

  ## API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def set_client(server \\ __MODULE__, client) do
    GenServer.call(server, {:set_client, client})
  end

  def parse_json(server \\ __MODULE__, text) do
    GenServer.cast(server, {:parse_json, text})
  end

  ## Callbacks

  def init(client) do
    {:ok, client}
  end

  def handle_call({:set_client, client}, _from, nil) do
    {:reply, :ok, client}
  end

  def handle_call({:set_client, client}, _from, orig_client) do
    if Process.alive?(orig_client) do
      Logger.error("Overriding client #{orig_client} => #{client} " <>
                   "in #{__MODULE__}")
      {:reply, :override, client}
    else
      {:reply, :ok, client}
    end
  end

  def handle_cast({:parse_json, text}, client) do
    send(client, {:parse_json, Poison.Parser.parse(text)})
    {:noreply, client}
  end
end
