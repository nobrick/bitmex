defmodule Bitmex.Websocket do
  @moduledoc """
  BitMEX WebSocket client.
  """

  import Process, only: [send_after: 3]

  defmacro __using__(_opts) do
    quote do
      use WebSockex
      require Logger
      alias Bitmex.Websocket.Parser

      @api_key Application.get_env(:bitmex, :api_key)
      @api_secret Application.get_env(:bitmex, :api_secret)
      @test_mode Application.get_env(:bitmex, :test_mode)
      @base "wss://" <> (@test_mode && "testnet" || "www") <>
            ".bitmex.com/realtime"
      @default_subscription ["orderBookL2:XBTUSD"]

      ## API

      def start_link(args \\ %{}, opts \\ []) do
        subscription = args[:subscribe] || @default_subscription
        auth_subscription = args[:auth_subscribe] || []
        parser = args[:parser] || Parser
        state = %{subscribe: subscription, auth_subscribe: auth_subscription,
                  heartbeat: 0, parser: parser}
        ws_opts =
          opts
          |> Keyword.put_new(:handle_initial_conn_failure, true)
          |> Keyword.put_new(:async, true)
        Logger.info "Starting #{__MODULE__} server..."
        {:ok, pid} = resp =
          WebSockex.start_link(@base, __MODULE__, state, ws_opts)
        :ok = Parser.set_client(parser, pid)
        resp
      end

      ## WebSocket Callbacks

      @impl true
      def handle_connect(_conn, state) do
        Logger.info("#{__MODULE__} connected")
        send(self(), :ws_subscribe)
        {:ok, state}
      end

      @impl true
      def handle_disconnect(disconnect_map, state) do
        Logger.warn("#{__MODULE__} disconnected: #{inspect disconnect_map}")
        {:reconnect, state}
      end


      @impl true
      def handle_pong(:pong, state) do
        {:ok, inc_heartbeat(state)}
      end

      @impl true
      def handle_frame({:text, text}, %{parser: parser} = state) do
        Parser.parse_json(parser, text)
        {:ok, inc_heartbeat(state)}
      end

      @impl true
      def handle_frame(msg, state) do
        Logger.warn("#{__MODULE__} received unexpected WebSocket response: " <>
                    inspect(msg))
        {:ok, state}
      end

      ## OTP Callbacks

      @impl true
      def handle_cast(_msg, state) do
        {:ok, state}
      end

      @impl true
      def handle_info(:ws_subscribe, %{subscribe: subscription,
                      auth_subscribe: auth_subscription} = state) do
        if match?([_|_], subscription) do
          subscribe(self(), subscription)
        end
        if match?([_|_], auth_subscription) do
          authenticate(self())
        end
        send_after(self(), {:heartbeat, :ping, 1}, 20_000)
        {:ok, state}
      end

      @impl true
      def handle_info({:heartbeat, :ping, expected_heartbeat},
                      %{heartbeat: heartbeat} = state) do
        if heartbeat >= expected_heartbeat do
          send_after(self(), {:heartbeat, :ping, heartbeat + 1}, 1_000)
          {:ok, state}
        else
          if not(@test_mode) do
            Logger.warn("#{__MODULE__} sent heartbeat ##{heartbeat} " <>
                        "due to low connectivity")
          end
          send_after(self(), {:heartbeat, :pong, heartbeat + 1}, 4_000)
          {:reply, :ping, state}
        end
      end

      @impl true
      def handle_info({:heartbeat, :pong, expected_heartbeat},
                      %{heartbeat: heartbeat} = state) do
        if heartbeat >= expected_heartbeat do
          send_after(self(), {:heartbeat, :ping, heartbeat + 1}, 1_000)
          {:ok, state}
        else
          Logger.warn("#{__MODULE__} terminated due to " <>
                      "no heartbeat ##{heartbeat}")
          {:close, state}
        end
      end

      @impl true
      def handle_info({:ws_reply, frame}, state) do
        {:reply, frame, state}
      end

      @impl true
      def handle_info({:parse_json, {:ok, payload}}, state) do
        case payload do
          %{"request" => %{"op" => "authKey"}, "success" => true} ->
            subscribe(self(), state[:auth_subscribe])
          _ ->
            handle_response(payload)
        end
        {:ok, state}
      end

      @impl true
      def handle_info({:parse_json, error}, state) do
        Logger.warn("Parse error #{error} in #{__MODULE__}")
        {:ok, state}
      end

      @impl true
      def handle_info(msg, state) do
        Logger.error("#{__MODULE__} received unexpected message: " <>
                     "#{inspect msg}\nstate: #{inspect state}")
        {:ok, state}
      end

      ## Helpers

      def reply_op(server, op, args) do
        json = Poison.encode!(%{op: op, args: args})
        send(server, {:ws_reply, {:text, json}})
      end

      def subscribe(server, channels) do
        reply_op(server, "subscribe", channels)
      end

      def authenticate(server) do
        nonce = Bitmex.Auth.nonce()
        sig = Bitmex.Auth.sign(@api_secret, "GET", "/realtime", nonce, "")
        reply_op(server, "authKey", [@api_key, nonce, sig])
      end

      def handle_response(resp) do
        Logger.debug("#{__MODULE__} received response: #{inspect resp}")
      end

      defp inc_heartbeat(%{heartbeat: heartbeat} = state) do
        Map.put(state, :heartbeat, heartbeat + 1)
      end

      defoverridable [handle_response: 1]
    end
  end
end
