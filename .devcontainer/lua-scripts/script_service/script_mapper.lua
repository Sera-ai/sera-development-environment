-- script_mapper.lua
local script_mapping = ngx.shared.script_mapping

return function(endpoint_and_method)
    return script_mapping:get(endpoint_and_method)
end