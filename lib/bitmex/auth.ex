defmodule Bitmex.Auth do
  @nonce_shift 1484899880000000

  def sign(api_secret, verb, uri, nonce, data) do
    %URI{path: path, query: query} = URI.parse(uri)
    encoded_uri =
      if query do
        path <> "?" <> Bitmex.URI.encode(query)
      else
        path
      end
    :sha256
    |> :crypto.hmac(api_secret, verb <> encoded_uri <> to_string(nonce) <> data)
    |> Base.encode16(case: :lower)
  end

  def nonce, do: :os.system_time(:micro_seconds) - @nonce_shift
end
