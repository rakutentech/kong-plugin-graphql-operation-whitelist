local typedefs = require "kong.db.schema.typedefs"


return {
  name = "graphql-operation-whitelist",
  fields = {
    { consumer = typedefs.no_consumer },
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { block_introspection_queries = { type = "boolean", default = false}, },
    }, }, },
  },
}