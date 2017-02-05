defmodule Bitmex.Auth do
  @nonce_shift 1484899880000000

  def sign(api_secret, verb, encoded_uri, nonce, data) do
    payload = verb <> encoded_uri <> to_string(nonce) <> data
    :sha256 |> :crypto.hmac(api_secret, payload) |> Base.encode16(case: :lower)
  end

  def nonce, do: :os.system_time(:micro_seconds) - @nonce_shift
end
