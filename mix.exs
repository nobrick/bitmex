defmodule Bitmex.Mixfile do
  use Mix.Project

  def project do
    [app: :bitmex,
     version: "0.2.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "BitMEX client library for Elixir",
     source_url: "https://github.com/nobrick/bitmex",
     homepage_url: "https://github.com/nobrick/bitmex",
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Bitmex.Application, []}]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev},
     {:websocket_client, "~> 1.2.1"},
     {:websockex, "~> 0.4.0"},
     {:poison, "~> 3.1.0"},
     {:httpoison, "~> 0.13.0"}]
  end

  defp package do
    [name: :bitmex,
     maintainers: ["Ming Qu"],
     licenses: ["MIT"],
     links: %{}
    ]
  end
end
