local access = require "kong.plugins.graphql-operation-whitelist.access"

local OperationWLHandler = {}

function OperationWLHandler:access(conf)
  access.execute(conf)
end


OperationWLHandler.PRIORITY = 790
OperationWLHandler.VERSION = "0.0.1"


return OperationWLHandler