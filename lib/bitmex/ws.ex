defmodule Bitmex.WS do
  @moduledoc """
  BitMEX WebSocket client.

  Behind the scenes, this module uses :websocket_client erlang libray.
  """

  import Logger, only: [info: 1, warn: 1]

  defmacro __using__(_opts) do
    quote do
      @behaviour :websocket_client
      @api_key Application.get_env(:bitmex, :api_key)
      @api_secret Application.get_env(:bitmex, :api_secret)
      @fsm_name {:local, __MODULE__}
      @test_mode Application.get_env(:bitmex, :test_mode)
      @base "wss://" <> (@test_mode && "testnet" || "www") <>
            ".bitmex.com/realtime"
      @ping_interval Application.get_env(:bitmex, :ping_interval, 5_000)

      ## API

      def start_link(args \\ %{}) do
        :crypto.start()
        :ssl.start()
        :websocket_client.start_link(@fsm_name, @base, __MODULE__, args, [])
      end

      def start_link(args, _), do: start_link(args)

      def send_op(server, op, args) do
        :websocket_client.send(server, {:text, Bitmex.WS.encode(op, args)})
      end

      def cast_op(server, op, args) do
        :websocket_client.cast(server, {:text, Bitmex.WS.encode(op, args)})
      end

      def subscribe(server, channels) do
        cast_op(server, "subscribe", channels)
      end

      def authenticate(server) do
        nonce = Bitmex.Auth.nonce()
        sig = Bitmex.Auth.sign(@api_secret, "GET", "/realtime", nonce, "")
        cast_op(server, "authKey", [@api_key, nonce, sig])
      end

      ## Callbacks

      def init(args) do
        subscription = args[:subscribe] || ["orderBookL2:XBTUSD"]
        auth_subscription = args[:auth_subscribe] || []
        ping_interval = args[:ping_interval] || @ping_interval
        {:once, %{subscribe: subscription, auth_subscribe: auth_subscription,
                  ping_interval: ping_interval}}
      end

      def onconnect(_ws_req, %{subscribe: subscription,
                               auth_subscribe: auth_subscription,
                               ping_interval: ping_interval} = state) do
        info("#{__MODULE__} connected")
        if match?([_|_], subscription) do
          subscribe(self(), subscription)
        end
        if match?([_|_], auth_subscription) do
          authenticate(self())
        end
        {:ok, state, ping_interval}
      end

      def ondisconnect(:normal, state) do
        info("#{__MODULE__} disconnected with reason :normal")
        {:ok, state}
      end

      def ondisconnect(reason, state) do
        warn("#{__MODULE__} disconnected: #{inspect reason}. Reconnecting")
        {:reconnect, state}
      end

      def websocket_handle({:pong, _}, _conn_state, state) do
        {:ok, state}
      end

      def websocket_handle(msg, _conn_state,
                           %{auth_subscribe: auth_subscription} = state) do
        with {:text, text} <- msg,
             {:ok, resp}   <- Poison.Parser.parse(text) do
          case resp do
            %{"request" => %{"op" => "authKey"}, "success" => true} ->
              subscribe(self(), auth_subscription)
            _ ->
              handle_response(resp)
          end
        else
          e ->
            warn("#{__MODULE__} received unexpected response: #{inspect e}")
        end
        {:ok, state}
      end

      def websocket_info(msg, _conn_state, state) do
        warn("#{__MODULE__} received unexpected erlang msg: #{inspect msg}")
        {:ok, state}
      end

      def websocket_terminate(reason, _conn_state, state) do
        warn("#{__MODULE__} closed in state #{inspect state} " <>
             "with reason #{inspect reason}")
        :ok
      end

      def handle_response(resp) do
        info("#{__MODULE__} received response: #{inspect resp}")
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  def encode(op, args) do
    Poison.encode!(%{op: op, args: args})
  end
end
