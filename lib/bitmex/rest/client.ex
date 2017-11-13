defmodule Bitmex.Rest.Client do
  use GenServer
  alias Bitmex.Rest.{HTTPClient, Requester}

  @compile {:inline, handle_request_call: 4}

  ## API

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def non_auth_get(uri, params) do
    HTTPClient.non_auth_get(uri, params)
  end

  def auth_get(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_get, uri, params}, :infinity)
  end

  def auth_post(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_post, uri, params}, :infinity)
  end

  def auth_put(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_put, uri, params}, :infinity)
  end

  def auth_delete(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_delete, uri, params}, :infinity)
  end

  ## Callbacks
  
  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call({:auth_get, uri, params}, user, state) do
    handle_request_call(uri, user, state, fn ->
      HTTPClient.auth_get(uri, params, stream_to: self())
    end)
  end

  @impl true
  def handle_call({:auth_post, uri, params}, user, state) do
    handle_request_call(uri, user, state, fn ->
      HTTPClient.auth_post(uri, params, stream_to: self())
    end)
  end

  @impl true
  def handle_call({:auth_put, uri, params}, user, state) do
    handle_request_call(uri, user, state, fn ->
      HTTPClient.auth_put(uri, params, stream_to: self())
    end)
  end

  @impl true
  def handle_call({:auth_delete, uri, params}, user, state) do
    handle_request_call(uri, user, state, fn ->
      HTTPClient.auth_delete(uri, params, stream_to: self())
    end)
  end

  ## Helpers

  defp handle_request_call(uri, user, state, fun) do
    {:ok, requester} = Requester.start_link()
    Requester.request(requester, user, uri, fun)
    {:noreply, state}
  end
end
