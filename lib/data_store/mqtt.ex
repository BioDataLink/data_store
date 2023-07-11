defmodule DataStore.Mqtt do
  def get_mqtt_config(), do: Application.get_env(:data_store, :mqtt)

  # Devuelve una configuración de child para un cliente mqtt, en el formato que
  # que espera un Supervisor
  # De momento no usamos las opciones, las tomamos deirectamente
  def child_spec(_) do
    config = get_mqtt_config()

    {Tortoise.Connection,
     client_id: config.client_id,
     server: {Tortoise.Transport.Tcp, host: config.host, port: config.port},
     handler: {__MODULE__, []},
     subscriptions: [{"metrics/#", 0}]}
  end

  # Opción de arranque a mano (para pruebas)
  def start_link() do
    {_, args} = child_spec([])
    Tortoise.Connection.start_link(args)
  end

  # Envía payload (serializado en JSON) al topic formado por
  # el parámetro "header" y el client_id configurado
  # Lo hacemos así para poder suscribirnos a "header" si queremos todo (header/#)
  # o a header/client_id para un cliente en concreto

  def send_data(header, payload) do
    config = get_mqtt_config()
    client_id = config.client_id
    topic = "#{header}/#{client_id}"
    payload = Jason.encode!(payload)
    Tortoise.publish(client_id, topic, payload)
  end

  # ya no nos vamos a suscribir usando esta función, porque al arrancar
  # ya nos suscribe a weather/#
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
    spawn(fn -> save(client_id, payload) end)
    {:ok, state}
  end

  def handle_message(topic_levels, payload, state) do
    payload = Jason.decode!(payload)
    IO.puts("MESSAGE FROM #{inspect(topic_levels)}: #{inspect(payload)}")
    {:ok, state}
  end

  def save(client_id, payload) do
    %{"metrics" => metrics, "timestamp" => timestamp} = Jason.decode!(payload)

    # data =
    #   Enum.reduce(metrics, [], fn {device, device_metrics}, acc ->
    #     Enum.reduce(device_metrics, acc, fn {type, value}, acc2 ->
    #       [
    #         %{
    #           terminal: client_id,
    #           timestamp: timestamp,
    #           device: device,
    #           type: type,
    #           value: value
    #         }
    #         | acc2
    #       ]
    #     end)
    #   end)

    for {device, device_metrics} <- metrics do
      for {type, value} <- device_metrics do
        medida = %{
          terminal: client_id,
          timestamp: timestamp,
          device: device,
          type: type,
          value: value
        }

        IO.puts("MEDIDA: #{inspect(medida)}")

        sql = """
        INSERT INTO metrics (uid, timestamp, type, value, terminal, device, metadata)
        VALUES ($1, $2, $3, $4, $5, $6, $7);
        """

        uid = Enum.random(0..1_111_111_111) |> to_string()
        {:ok, timestamp} = NaiveDateTime.from_iso8601(timestamp)
        timestamp = DateTime.from_naive!(timestamp, "Etc/UTC")
        Postgrex.query!(:postgres, sql, [uid, timestamp, type, value, client_id, device, %{}])
      end
    end
  end
end
