return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "graphql_operation_whitelist" (
        "id"            UUID                         PRIMARY KEY,
        "created_at"    TIMESTAMP WITHOUT TIME ZONE  DEFAULT (CURRENT_TIMESTAMP(0) AT TIME ZONE 'UTC'),
        "consumer_id"   UUID                         REFERENCES "consumers" ("id") ON DELETE CASCADE,        
        "hash"          TEXT                         UNIQUE,
        "name"          TEXT                         UNIQUE,
        "signature"     TEXT                         ,
        "operation"     TEXT                         
      );

      DO $$
      BEGIN
        CREATE INDEX IF NOT EXISTS "operation_whitelist_consumer_id_idx" ON "graphql_operation_whitelist" ("consumer_id");
      EXCEPTION WHEN UNDEFINED_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
  },

  cassandra = {
    up = [[
      CREATE TABLE IF NOT EXISTS graphql_operation_whitelist (
        id          uuid PRIMARY KEY,
        created_at  timestamp,
        consumer_id uuid,
        hash        text,
        name        text,
        signature   text,
        operation   text
      );
      CREATE INDEX IF NOT EXISTS ON graphql_operation_whitelist(hash);
      CREATE INDEX IF NOT EXISTS ON graphql_operation_whitelist(consumer_id);
    ]],
  },
}
