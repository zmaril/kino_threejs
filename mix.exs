defmodule KinoThreeJS.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "three.js integration with Livebook"

  def project do
    [
      app: :kino_threejs,
      version: @version,
      description: @description,
      name: "KinoThreeJS",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      mod: {KinoThreeJS.Application, []}
    ]
  end

  defp deps do
    [
      {:kino, "~> 0.7"},
      {:table, "~> 0.1.0"},
      {:maplibre, "~> 0.1.3"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "components",
      source_url: "https://github.com/livebook-dev/kino_maplibre",
      source_ref: "v#{@version}",
      extras: ["guides/components.livemd"],
      groups_for_modules: [
        Kinos: [
          Kino.MapLibre
        ]
      ]
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/livebook-dev/kino_maplibre"
      }
    ]
  end
end
