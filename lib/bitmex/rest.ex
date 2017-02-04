defmodule Bitmex.Rest do
  @moduledoc """
  BitMEX Rest API client.
  """

  require Logger
  import Bitmex.Rest.Client, only: [auth_get: 1, auth_post: 2]

  ## API

  def close_position(symbol, price) do
    auth_post("/order", %{"symbol" => symbol, "price" => price,
              "ordType" => "Limit", "execInst" => "Close"})
  end

  def order(params) do
    auth_post("/order", params)
  end

  def position do
    auth_get("/position")
  end
end
