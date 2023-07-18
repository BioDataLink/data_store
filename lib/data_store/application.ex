defmodule DataStore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Postgrex, DataStore.Db.get_postgres_config()},
      {Tortoise.Connection, DataStore.Mqtt.get_tortoise_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataStore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Postgrex.query!(:postgres, sql, [])
