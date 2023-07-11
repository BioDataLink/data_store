defmodule DataStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_store,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DataStore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependendencia para formato datos json
      {:jason, "~> 1.4"},
      # Cliente tortoise MQTT
      {:tortoise, "~> 0.10.0"},
      # base de datos usando Ecto y driver Postgres
      {:ecto_sql, "~> 3.9"},
      {:postgrex, "~> 0.16"}
    ]
  end
end
