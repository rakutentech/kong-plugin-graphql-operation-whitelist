local path = (...):gsub('%.[^%.]+$', '')
local printer = require (path .. '.printer')
local parse = require (path .. '.parse')

local sha256 = require "resty.sha256"
local encode_base64 = ngx.encode_base64

local util = {}

local function generate_signature_hash(s) 
  local digest = sha256:new()
  digest:update(s)
  local hash = encode_base64(digest:final())
  return hash
end 

local function generate_operation_signature(tree, operation_name) 
  local operation_signature = printer(tree, operation_name)
  return operation_signature
end 

local function parse_query(query) 
  local ok, ast = pcall(parse, query)

  if not ok then 
    return false, { status = 400, message = "Operation query format is incorrect" }
  end

  return true, ast
end

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function is_introspection_query(document) 
  if document and document.definitions then
    for definitionIndex, definition in ipairs(document.definitions) do
      if definition.kind == 'operation' and definition.selectionSet and definition.selectionSet.selections then
        local selections = definition.selectionSet.selections
        for selectionIndex, selection in pairs(selections) do
          if selection.name 
              and selection.name.value 
              and not starts_with(selection.name.value, '__schema') then
            return false
          end
        end
      end
    end 
  end

  return true
end

function util.generate_fingerprint(query, operation_name, ignore_introspection)
  -- Parse the graphql document and get an AST
  local parse_success, parse_output = parse_query(query)
  if not parse_success then 
    return false, parse_output
  end

  if ignore_introspection then
    -- If the operation is an operation query, let it pass
    if is_introspection_query(parse_output) then
      return true
    end
  end

  -- Generate operation signature
  local operation_signature = generate_operation_signature(parse_output, operation_name)

  -- Generate operation hash
  local hash = generate_signature_hash(operation_signature)

  return true, hash, operation_signature
end

function util.retrieve_operation_details() 
  local operation_details = {}

  local request_method = kong.request.get_method()

  if not request_method == "POST" then
    -- TODO: Implement support for GET request by parsing the "query" query string
    return false, { status = 405, message = "Method Not Allowed" }
  end

  -- TODO: Add support for Content-type: application/graphql
  local body, err = kong.request.get_body('application/json')
  if err then
      kong.log.err(err)
      return false, err
  end

  if not body.operationName then
    return false, { status = 400, message = "Missing operation name field" }
  end

  if not body.query then 
    return false, { status = 400, message = "Missing operation query" }
  end

  operation_details.name = body.operationName
  operation_details.query = body.query

  return true, operation_details
end

return util