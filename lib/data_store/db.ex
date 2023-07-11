defmodule DataStore.Db do
  def create_metrics_table() do
    sql = """
      CREATE TABLE metrics (
      uid VARCHAR(255) PRIMARY KEY,
      timestamp TIMESTAMPTZ,
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
end
