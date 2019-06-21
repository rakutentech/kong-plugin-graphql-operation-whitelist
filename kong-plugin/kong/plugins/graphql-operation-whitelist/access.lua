local path = (...):gsub('%.[^%.]+$', '')
local util = require(path .. '.util')

-- local function load_operation(hash) 

--   local operation, err = kong.db.graphql_operation_whitelist:select_by_hash(hash)
  
--   if not operation then
--     return nil, err
--   end
--   return operation

-- end

local function is_operation_whitelisted(operation_hash) 

  --TODO:we are not using the cache because I can't get the Automatic cache invalidation to work in my dev env.
  local operation, err = kong.db.graphql_operation_whitelist:select_by_hash(operation_hash)
  
  if err then
    kong.log.err(err)
    return false, { status = 500, message = "Unexpected error" }
  end

  if not operation then
    return false, { status = 401, message = "Unauthorized Operation" }
  end

  return operation
  
  -- local operation_cache_key = kong.db.keyauth_credentials:cache_key(operation_hash)

  -- local operation, err = kong.cache:get(operation_cache_key, nil, 
  --                                       load_operation, operation_hash)
  -- if err then
  --   kong.log.err(err)
  --   return false, { status = 500, message = "Unexpected error" }
  -- end
    
  -- -- no operation in cache nor datastore, it is invalid, return 401
  -- if not operation then
  --   return false, { status = 401, message = "Unauthorized Operation" }
  -- end

  -- return true
end

local function verify_operation() 
  -- Get Operation details: name and body
  local details_ok, operation_details = util.retrieve_operation_details()

  if not details_ok then
    return false, operation_details
  end

   -- Generate operation Hash 
  local extract_success, hash = util.generate_fingerprint(operation_details.query, operation_details.name, true)

  if not extract_success then
    return false, hash
  end

  -- TODO: this is an ignored introspection query but it's difficult to understand from the current code structure 
  if extract_success and not hash then
    return true
  end

  -- Verify this hash is whitelisted
  if not is_operation_whitelisted(hash) then
    kong.log("❌ Operation Signature Hash is not whitelisted, blocking " .. operation_details.name)

    return false, { status = 401, message = "Unauthorized operation" }
  end

  kong.log("✅ Operation Signature Hash is valid, forwarding " .. operation_details.name)
  return true
end


local _M = {}

function _M.execute(conf)

  local ok, err = verify_operation(conf)

  if not ok then 
    return kong.response.exit(err.status, { message = err.message })
  end
end


return _M