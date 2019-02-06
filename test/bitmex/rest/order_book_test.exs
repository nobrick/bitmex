defmodule Bitmex.Rest.OrderBookTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Bitmex.Rest.OrderBook

  setup_all do
    HTTPoison.start()
  end

  test ".get ok" do
    use_cassette "rest/order_book/get_ok" do
      assert {:ok,
              %HTTPoison.Response{
                body: [
                  %{"id" => _, "price" => _, "side" => _, "size" => _, "symbol" => "XBTUSD"} | _
                ]
              }} = Bitmex.Rest.OrderBook.get(symbol: "XBTUSD")
    end
  end

  test ".get timeout" do
    use_cassette "rest/order_book/get_timeout" do
      assert Bitmex.Rest.OrderBook.get(symbol: "XBTUSD") ==
               {:error, %HTTPoison.Error{id: nil, reason: "timeout"}}
    end
  end
end
