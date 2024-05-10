-- script_mapper.lua
local endpoint_to_script = {
    ["localhost:/api/users:GET"] = "test.lua",
    ["localhost:/api/auth:GET"] = "auth_test.lua",
    -- Add more endpoint-method combinations here...
}

return function(endpoint_and_method)
    return endpoint_to_script[endpoint_and_method]
end
