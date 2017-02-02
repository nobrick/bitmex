defmodule Bitmex.Rest do
  require Logger
  import Bitmex.Rest.Client, only: [auth_get: 1, auth_post: 2]

  ## API

  def close_position(symbol \\ "XBTUSD", price) do
    auth_post("/order", %{"symbol" => symbol, "price" => price,
              "ordType" => "Limit", "execInst" => "Close"})
  end

  def order(params) do
    auth_post("/order", params)
  end

  def position do
    auth_get("/position")
  end

  ## Helpers

  def normalize_usd(usd) do
    Float.floor(usd, 2)
  end
end
