import Config

config :data_store,
  mqtt: %{
    client_id: "data_store_1",
    host: "127.0.0.1",
    port: 1883,
    user: "",
    password: ""
  }

config :data_store,
  postgres: %{
    hostname: "localhost",
    username: "postgres",
    password: "postgres",
    database: "biodatalink"
  }
