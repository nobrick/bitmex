defmodule Bitmex.Rest.Client do
  use GenServer
  alias Bitmex.Rest.HTTPClient

  ## API

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def non_auth_get(uri, params) do
    HTTPClient.non_auth_get(uri, params)
  end

  def auth_get(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_get, uri, params})
  end

  def auth_post(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_post, uri, params})
  end

  def auth_put(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_put, uri, params})
  end

  def auth_delete(server \\ __MODULE__, uri, params) do
    GenServer.call(server, {:auth_delete, uri, params})
  end

  ## Callbacks
  
  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call({:auth_get, uri, params}, _from, state) do
    {:reply, HTTPClient.auth_get(uri, params), state}
  end

  @impl true
  def handle_call({:auth_post, uri, params}, _from, state) do
    {:reply, HTTPClient.auth_post(uri, params), state}
  end

  @impl true
  def handle_call({:auth_put, uri, params}, _from, state) do
    {:reply, HTTPClient.auth_put(uri, params), state}
  end

  @impl true
  def handle_call({:auth_delete, uri, params}, _from, state) do
    {:reply, HTTPClient.auth_delete(uri, params), state}
  end
end
