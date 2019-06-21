local typedefs = require "kong.db.schema.typedefs"

return {
  graphql_operation_whitelist = {
    name                = "graphql_operation_whitelist",
    primary_key         = { "id" },
    endpoint_key        = "hash",
    cache_key           = { "hash" },
    fields = {
      {
        id = typedefs.uuid,
      },
      {
        created_at = typedefs.auto_timestamp_s,
      },
      { 
        consumer = { 
          type = "foreign", 
          reference = "consumers", 
          default = ngx.null, 
          on_delete = "cascade", 
        }, 
      },
      {
        hash = {
          type      = "string",
          required  = true,
          unique    = true,
          auto      = false,
        },
      },
      {
        name = {
          type      = "string",
          required  = true,
          unique    = true,
          auto      = false,
        }
      },
      {
        signature = {
          type      = "string",
          required  = false,
          unique    = false,
          auto      = false,
        }
      },  
      {
        operation = {
          type      = "string",
          required  = false,
          unique    = false,
          auto      = false,
        }
      },     
    },
  },
}