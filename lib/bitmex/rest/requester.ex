defmodule Bitmex.Rest.Requester do
  use GenServer
  require Logger
  alias Bitmex.Rest.{HTTPClient, RateLimiter}

  ## API
  
  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def request(server, user, uri, fun) do
    GenServer.call(server, {:request, user, uri, fun}, :infinity)
  end

  ## Callbacks
  
  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call({:request, user, uri, fun}, client, _state) do
    case fun.() do
      {:ok, %{id: id}} ->
        {:noreply, %{client: client, user: user, async_id: id, response: "",
                     request_url: HTTPClient.api_uri <> uri}}
      error ->
        Logger.error "Unexpected failure #{inspect error} in #{__MODULE__}"
        GenServer.reply(user, error)
        {:stop, :normal, :error, nil}
    end
  end

  @impl true
  def handle_info(%HTTPoison.AsyncStatus{code: code},
                  %{client: client} = state) do
    GenServer.reply(client, :ok)
    {:noreply, Map.put(state, :status_code, code)}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncHeaders{headers: headers}, state) do
    RateLimiter.set_rate(headers)
    {:noreply, Map.put(state, :headers, headers)}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk},
                  %{response: response} = state) do
    {:noreply, Map.put(state, :response, response <> chunk)}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncEnd{}, %{user: user,
                  status_code: status_code, headers: headers,
                  response: response, request_url: request_url} = state) do
    resp = %HTTPoison.Response{status_code: status_code, headers: headers,
      body: Poison.decode!(response), request_url: request_url}
    GenServer.reply(user, {:ok, resp})
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error "#{__MODULE__} received unexpected message: " <>
                 "#{inspect msg}\nstate: #{inspect state}"
    {:noreply, state}
  end
end
