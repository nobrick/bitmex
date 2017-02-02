defmodule Bitmex.Rest.Client do
  use HTTPoison.Base

  @api_key Application.get_env(:bitmex, :api_key)
  @api_secret Application.get_env(:bitmex, :api_secret)
  @api_host "https://www.bitmex.com"
  @api_path "/api/v1"
  @api_uri @api_host <> @api_path
  @nonce_shift 1484899880000000

  def auth_get(uri) do
    get(uri, auth_headers("GET", uri))
  end

  def auth_post(uri, params) do
    body = Bitmex.URI.encode_query(params)
    headers = "POST" |> auth_headers(uri, body) |> put_content_type(:params)
    post(uri, body, headers)
  end

  def auth_post_via_json(uri, params) do
    body = params |> Poison.Encoder.encode([]) |> IO.iodata_to_binary
    headers = "POST" |> auth_headers(uri, body) |> put_content_type(:json)
    post(uri, body, headers)
  end

  defp put_content_type(headers, :params) do
    Keyword.put(headers, :"Content-Type", "application/x-www-form-urlencoded")
  end

  defp put_content_type(headers, :json) do
    Keyword.put(headers, :"Content-Type", "application/json")
  end

  ## Helpers

  defp auth_headers(verb, uri, data \\ "") do
    nonce = nonce()
    sig = Bitmex.Auth.sign(@api_secret, verb, @api_path <> uri, nonce, data)
    ["api-nonce": "#{nonce}", "api-key": @api_key, "api-signature": sig]
  end

  defp nonce, do: :os.system_time(:micro_seconds) - @nonce_shift

  ## HTTPoison callbacks

  def process_url(url), do: @api_uri <> url

  def process_response_body(body), do: Poison.decode!(body)

  def process_request_headers(headers) do
    Keyword.merge(headers, ["Accept": "application/json",
                            "X-Requested-With": "XMLHttpRequest"])
  end
end
