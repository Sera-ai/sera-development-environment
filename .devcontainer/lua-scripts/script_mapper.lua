-- script_mapper.lua
local endpoint_to_script = {
    ["localhost:/api/users:GET"] = "test.lua",
    ["localhost:/api/users2:GET"] = "test2.lua",
    -- Add more endpoint-method combinations here...
}

return function(endpoint_and_method)
    return endpoint_to_script[endpoint_and_method]
end
