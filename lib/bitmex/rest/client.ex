defmodule Bitmex.Rest.Client do
  use HTTPoison.Base
  import Bitmex.URI, only: [encode_query: 1]

  @api_key Application.get_env(:bitmex, :api_key)
  @api_secret Application.get_env(:bitmex, :api_secret)
  @api_host "https://www.bitmex.com"
  @api_path "/api/v1"
  @api_uri @api_host <> @api_path

  def non_auth_get(uri, params \\ []) do
    uri |> uri_with_query(params) |> get
  end

  def auth_get(uri, params \\ []) do
    query = uri_with_query(uri, params)
    get(query, auth_headers("GET", query))
  end

  def auth_post(uri, params) do
    auth_request(:post, uri, params)
  end

  def auth_put(uri, params) do
    auth_request(:put, uri, params)
  end

  def auth_delete(uri, params) do
    auth_request(:delete, uri, params)
  end

  def auth_request(verb, uri, params)
  when verb in [:post, :put, :delete] do
    body = encode_query(params)
    headers =
      verb
      |> to_string
      |> String.upcase
      |> auth_headers(uri, body)
      |> put_content_type(:params)
    request(verb, uri, body, headers, [])
  end

  def auth_post_via_json(uri, params) do
    body = Poison.encode!(params)
    headers = "POST" |> auth_headers(uri, body) |> put_content_type(:json)
    post(uri, body, headers)
  end

  defp put_content_type(headers, :params) do
    Keyword.put(headers, :"Content-Type", "application/x-www-form-urlencoded")
  end

  defp put_content_type(headers, :json) do
    Keyword.put(headers, :"Content-Type", "application/json")
  end

  def uri_with_query(uri, []), do: uri
  def uri_with_query(uri, %{}), do: uri
  def uri_with_query(uri, params), do: "#{uri}?#{encode_query(params)}"

  ## Helpers

  defp auth_headers(verb, encoded_uri, data \\ "") do
    nonce = Bitmex.Auth.nonce()
    sig = Bitmex.Auth.sign(@api_secret, verb, @api_path <> encoded_uri,
                           nonce, data)
    ["api-nonce": to_string(nonce), "api-key": @api_key, "api-signature": sig]
  end


  ## HTTPoison callbacks

  def process_url(url), do: @api_uri <> url

  def process_response_body(body), do: Poison.decode!(body)

  def process_request_headers(headers) do
    Keyword.merge(headers, ["Accept": "application/json",
                            "X-Requested-With": "XMLHttpRequest"])
  end
end
