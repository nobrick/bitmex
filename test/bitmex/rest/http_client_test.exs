defmodule Bitmex.Rest.HTTPClientTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Bitmex.Rest.HTTPClient

  setup_all do
    HTTPoison.start()
  end

  test ".non_auth_get ok" do
    use_cassette "rest/http_client/non_auth_get_ok" do
      assert {:ok,
              %HTTPoison.Response{
                body: [%{"symbol" => _}]
              }} = Bitmex.Rest.HTTPClient.non_auth_get("/instrument", %{start: 0, count: 1})
    end
  end

  test ".non_auth_get timeout" do
    use_cassette "rest/http_client/non_auth_get_timeout" do
      assert Bitmex.Rest.HTTPClient.non_auth_get("/instrument", %{start: 0, count: 1}) ==
               {:error, %HTTPoison.Error{id: nil, reason: "timeout"}}
    end
  end
end
