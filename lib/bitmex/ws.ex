defmodule Bitmex.WS do
  defmacro __using__(_opts) do
    quote do
      require Logger

      @behaviour :websocket_client
      @fsm_name {:local, __MODULE__}
      @base "wss://www.bitmex.com/realtime?heartbeat=true"
      @heartbeat Application.get_env(:bitmex, :heartbeat_interval, 7_000)

      ## API
      def start_link(args \\ %{}) do
        :crypto.start()
        :ssl.start()
        :websocket_client.start_link(@fsm_name, @base, __MODULE__, args, [])
      end

      def send_op(server, op, args) do
        :websocket_client.send(server, {:text, Bitmex.WS.encode(op, args)})
      end

      def cast_op(server, op, args) do
        :websocket_client.cast(server, {:text, Bitmex.WS.encode(op, args)})
      end

      def subscribe(server, channels) do
        cast_op(server, "subscribe", channels)
      end

      ## Callbacks

      def init(args) do
        subscription = Map.get(args, :subscribe, ["orderBook10:XBTUSD"])
        {:once, %{subscribe: subscription}}
      end

      def onconnect(_ws_req, %{subscribe: subscription} = state) do
        Logger.info("Bitmex.WS connected")
        subscribe(self(), subscription)
        {:ok, state, @heartbeat}
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
        with {:text, text} <- msg,
             {:ok, resp}   <- Poison.Parser.parse(text) do
          handle_response(resp)
        else
          e ->
            Logger.warn("Bitmex.WS received unexpected response: #{inspect e}")
        end
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

      def handle_response(resp) do
        Logger.info("Bitmex.WS received response: #{inspect resp}")
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  def encode(op, args) do
    %{op: op, args: args} |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
  end
end
