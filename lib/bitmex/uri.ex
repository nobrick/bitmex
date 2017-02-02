defmodule Bitmex.URI do
  def encode(value) do
    value
    |> to_string
    |> URI.encode
    |> String.replace("%20", "+")
    |> String.replace(":", "%3A")
  end

  def encode_query(enum) do
    Enum.map_join(enum, "&", fn {k, v} -> encode(k) <> "=" <> encode(v) end)
  end
end
