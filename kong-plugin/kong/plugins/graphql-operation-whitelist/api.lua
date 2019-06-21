local path = (...):gsub('%.[^%.]+$', '')
local util = require(path .. '.util')

local endpoints = require "kong.api.endpoints"

local kong               = kong
local whitelist_schema   = kong.db.graphql_operation_whitelist.schema
local consumers_schema   = kong.db.consumers.schema

local HTTP_NOT_FOUND = 404

return {
  ["/consumers/:consumers/gql-op-whitelist"] = {
    schema = whitelist_schema,
    methods = {
      before = function(self, db, helpers)
        local consumer, _, err_t = endpoints.select_entity(self, db, consumers_schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not consumer then
          return kong.response.exit(HTTP_NOT_FOUND, { message = "Not found" })
        end

        self.consumer = consumer

        if self.req.method == "POST" 
          and self.req.headers["content-type"]
           and self.req.headers["content-type"] == "application/json" then

            if not self.params.query or not self.params.operationName then
              kong.log("\n\n ℹ  This is not a GraphQL document, ignore")
              return
            end

            self.name = self.params.operationName
            self.operation = self.params.query

             -- Generate operation Hash and Signature
            local extract_success, hash, signature = util.generate_fingerprint(self.params.query, self.params.operationName, true)
            
            if not extract_success then
              return
            end

            -- TODO: this is an ignored introspection query but it's difficult to understand from the current code structure 
            if extract_success and not hash then
              return
            end

            self.hash = hash
            self.signature = signature
        end
      end,
      GET = endpoints.get_collection_endpoint(
        whitelist_schema, consumers_schema, "consumer"),
      POST  = function(self, db, helpers)

        self.args.post.consumer = { id = self.consumer.id }

        self.args.post.name = self.name
        self.args.post.operation = self.operation
        self.args.post.hash = self.hash
        self.args.post.signature = self.signature

        self.args.post.query = nil
        self.args.post.operationName = nil
        self.args.post.variables = nil
        
        return endpoints.post_collection_endpoint(whitelist_schema)(self, db, helpers)
      end,
    },
  },
  ["/consumers/:consumers/gql-op-whitelist/:graphql_operation_whitelist"] = {
    schema = whitelist_schema,
    methods = {
      GET  = endpoints.get_entity_endpoint(whitelist_schema),
      DELETE = endpoints.delete_entity_endpoint(whitelist_schema),
    },
  },
  ["/gql-op-whitelist/"] = {
    schema = whitelist_schema,
    methods = {
      GET = endpoints.get_collection_endpoint(whitelist_schema),
    }
  },
  ["/gql-op-whitelist/:graphql_operation_whitelist"] = {
    schema = whitelist_schema,
    methods = {
      GET = endpoints.get_collection_endpoint(whitelist_schema),
      DELETE = endpoints.delete_entity_endpoint(whitelist_schema),
    }
  },
  ["/gql-op-whitelist/:graphql_operation_whitelist/consumer"] = {
    schema = consumers_schema,
    methods = {
      GET = endpoints.get_entity_endpoint(
        whitelist_schema, consumers_schema, "consumer"),
    }
  },
}