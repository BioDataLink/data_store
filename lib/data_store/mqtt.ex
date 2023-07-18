defmodule DataStore.Mqtt do
  def get_mqtt_config(), do: Application.get_env(:data_store, :mqtt)

  def get_tortoise_config() do
    config = get_mqtt_config()

    [
      client_id: config.client_id,
      server: {Tortoise.Transport.Tcp, host: config.host, port: config.port},
      handler: {__MODULE__, []},
      subscriptions: [{"metrics/#", 1}]
    ]
  end

  # Opción de arranque a mano (para pruebas)
  def start_link() do
    tortoise_config = get_tortoise_config()
    Tortoise.Connection.start_link(tortoise_config)
  end

  # Envía payload (serializado en JSON) al topic formado por
  # el parámetro "header" y el client_id configurado
  # Lo hacemos así para poder suscribirnos a "header" si queremos todo (header/#)
  # o a header/client_id para un cliente en concreto

  def send_data(topic, payload) do
    config = get_mqtt_config()
    client_id = config.client_id
    payload = Jason.encode!(payload)
    Tortoise.publish(client_id, topic, payload, [{:qos, 1}])
  end

  # ya no nos vamos a suscribir usando esta función, porque al arrancar
  # ya nos suscribe a metricd/#
  # pero podríamos usarla para suscribirnos a otro topic

  def subscribe(topic) do
    get_mqtt_config()
    |> Tortoise.Connection.subscribe([{topic, 0}])
  end

  # A continuación tenemos que escribir un handler para tortoise
  # ---------------
  use Tortoise.Handler

  def init(opts) do
    IO.puts("IN INIT: #{inspect(opts)}")
    {:ok, nil}
  end

  # Se llama al cambiar estado conexión
  def connection(status, state) do
    IO.puts("CONNECTION: #{status}")
    {:ok, state}
  end

  # Para recibir mensajes de los topics
  # topic_levels es un array de strings. Para el topic "a/b/c", sería ["a", "b", "c"]
  # payload viene binario, pero sabemos que contien un JSON que convertimos de vuelta a un mapa elixir
  def handle_message(["metrics", client_id], payload, state) do
    IO.puts("SAVE")
    save(client_id, payload)
    {:ok, state}
  end

  def handle_message(topic_levels, payload, state) do
    payload = Jason.decode!(payload)
    IO.puts("MESSAGE FROM #{inspect(topic_levels)}: #{inspect(payload)}")
    {:ok, state}
  end

  def save(client_id, payload) do
    %{"metrics" => metrics} = Jason.decode!(payload)

    for %{"device" => device, "class" => class, "time" => time, "read" => read} <- metrics do
      metric = %{
        terminal: client_id,
        timestamp: time,
        device: device,
        type: class,
        value: read
      }

      DataStore.Db.insert_metric(metric)
    end
  end
end
