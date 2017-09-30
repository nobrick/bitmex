defmodule Bitmex.AuthTest do
  use ExUnit.Case, async: true

  @api_secret "chNOOS4KvNXR_Xq4k4c9qsfoKWvnDecLATCRlcBwyKDYnWgO"

  test "GET authentication" do
    verb = "GET"
    path = ~S(/api/v1/instrument?filter={"symbol": "XBTM15"})
    nonce = 1429631577690
    data = ""
    signature =
      "9f1753e2db64711e39d111bc2ecace3dc9e7f026e6f65b65c4f53d3d14a60e5f"
    uri = Bitmex.URI.encode_query(path)
    assert Bitmex.Auth.sign(@api_secret, verb, uri, nonce, data) == signature
  end

  test "POST authentication" do
    verb = "POST"
    path = "/api/v1/order"
    nonce = 1429631577995
    data =
      ~S({"symbol":"XBTM15","price":219.0,) <>
      ~S("clOrdID":"mm_bitmex_1a/oemUeQ4CAJZgP3fjHsA","orderQty":98})
    signature =
      "93912e048daa5387759505a76c28d6e92c6a0d782504fc9980f4fb8adfc13e25"
    assert Bitmex.Auth.sign(@api_secret, verb, path, nonce, data) == signature
  end
end
