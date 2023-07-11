defmodule DataStore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    postgres_config =
      Application.get_env(:data_store, :postgres)
      |> Map.to_list()
      |> Keyword.put(:name, :postgres)

    children = [
      {Postgrex, postgres_config},
      DataStore.Mqtt.child_spec([]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataStore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Postgrex.query!(:postgres, sql, [])
