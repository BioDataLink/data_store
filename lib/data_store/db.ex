defmodule DataStore.Db do
  def get_postgres_config() do
    Application.get_env(:data_store, :postgres)
    |> Map.to_list()
    |> Keyword.put(:name, :postgres)
  end

  def create_metrics_table() do
    sql = """
      CREATE TABLE metrics (
      uid VARCHAR(255) PRIMARY KEY,
      timestamp TIMESTAMP WITHOUT TIME ZONE,
      type VARCHAR(255),
      value FLOAT,
      terminal VARCHAR(255),
      device VARCHAR(255),
      metadata JSONB
    );
    """

    Postgrex.query!(:postgres, sql, [])

    sql = "CREATE INDEX idx_metrics_type_timestamp ON metrics (type, timestamp);"
    Postgrex.query!(:postgres, sql, [])
  end

  def insert_metric(metric) do
    %{
      terminal: terminal,
      timestamp: timestamp,
      device: device,
      type: type,
      value: value
    } = metric

    sql = """
    INSERT INTO metrics (uid, timestamp, type, value, terminal, device, metadata)
    VALUES ($1, $2, $3, $4, $5, $6, $7);
    """

    uid = Enum.random(1_111_111_111..9_999_999_999) |> to_string()
    timestamp = NaiveDateTime.from_iso8601!(timestamp)
    Postgrex.query!(:postgres, sql, [uid, timestamp, type, value, terminal, device, %{}])
  end
end
