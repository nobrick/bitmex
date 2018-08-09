# BitMEX
BitMEX client library for Elixir.

## Documentation
See the [online documentation](https://hexdocs.pm/bitmex/) for more information.

## Installation
Add :bitmex to your list of dependencies in mix.exs:

```elixir
def deps do
  [{:bitmex, "~> 0.2"}]
end
```

Add your app's `api_key` and `api_secret` to `config/config.exs`:
```
config :bitmex, api_key: ""
config :bitmex, api_secret: ""
config :bitmex, test_mode: false
```

Set `test_mode` to true if you want to simulate your app using BitMEX Testnet instead of the production version.

## REST API

You may call methods in modules `Bitmex.Rest.*` (eg. `Bitmex.Rest.OrderBook`) to access the REST API.

View the [Hex Documentation](https://hexdocs.pm/bitmex/) and [BitMEX API Explorer](https://www.bitmex.com/api/explorer/) for a full list of endpoints and return types.

### Usage Examples

#### Position
Get the current position:
```elixir
Bitmex.Rest.Position.get()
```

#### Orders
Get all your open orders:
```elixir
Bitmex.REST.Order.get_open()
```

Create a order:
```elixir
params_bi = %{"symbol" => "XBTUSD", "side" => "Buy", "orderQty" => 15,
              "ordType" => "Market"}
Bitmex.Rest.Order.create(params_bi)
```

Create a bulk order:
```elixir
p1 = %{"symbol" => "XBTUSD", "side" => "Buy", "orderQty" => 15,
       "price" => 4000.1, "ordType" => "Limit"}
Bitmex.Rest.Order.create_bulk(%{orders: [p1, p1]})
```

### Rate Limit
You may query the rate limit counter using `Bitmex.Rest.RateLimiter.remaining()`. It automatically logs the rate limit info responded from your last REST API request.

## WebSocket API

To enable WebSocket subscriptions, use `Bitmex.WS` module and override the `handle_response` function:

```elixir
defmodule Caravan.WS.MessageHandler do
  use Bitmex.WS
  def handle_response(resp), do: Caravan.WS.process(resp)
end

defmodule Caravan.WS do
  require Logger
  import Task.Supervisor, only: [start_child: 2]

  # API

  def start_link(opts \\ []) do
    Agent.start_link(fn -> [] end, opts)
  end

  def process(resp) do
    Agent.cast(__MODULE__, fn _ ->
      start_child(TemporaryTaskSup, fn -> handle_response(resp) end)
      []
    end)
  end

  # Your callbacks

  @doc """
  Handles order book data.
  """
  def handle_response(%{"table" => "orderBook10", "action" => action,
                        "data" => datums}) do
    # ...
  end

  @doc """
  Handles position data.
  """
  def handle_response(%{"table" => "position", "action" => action,
                        "data" => datums}) do
    # ...
  end

  @doc """
  Handles margin data.
  """
  def handle_response(%{"table" => "margin", "action" => _action,
                        "data" => [_datum]}) do
    # ...
  end

  @doc """
  Handles order data.
  """
  def handle_response(%{"table" => "order", "action" => action,
                        "data" => datums}) do
    # ...
  end

  @doc """
  Handles table subscriptions.
  """
  def handle_response(%{"request" => %{"op" => "subscribe"},
                      "subscribe" => table, "success" => true}) do
    Logger.info "Subscribed #{table}"
    # ...
  end

  @doc """
  Handles unexpected data.
  """
  def handle_response(resp) do
    Logger.warn inspect(resp, limit: 500)
    # ...
  end
end
```

## License

[The MIT License](https://github.com/nobrick/bitmex/blob/master/LICENSE)
