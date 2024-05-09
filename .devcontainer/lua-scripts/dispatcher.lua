local script_cache = ngx.shared.script_cache
local mapper = require "script_mapper"

local function dispatch()
    local request_host = ngx.var.host
    local request_uri = ngx.var.uri
    local request_method = ngx.var.request_method  -- "GET", "POST", etc.

    -- Create a unique key by combining the request URI and method
    local key = request_host .. ":" .. request_uri .. ":" .. request_method

    -- Get the appropriate script name using the mapper and cache mechanism
    local script_name = mapper(key)

    if script_name then
        -- Retrieve the compiled script function from the cache
        local script_func = script_cache:get(script_name)

        if not script_func then
            local script_path = "/etc/nginx/lua-scripts/generated/" .. script_name
            local loaded_func, err = loadfile(script_path)

            if not loaded_func then
                ngx.log(ngx.ERR, "Failed to load script: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            else
                -- Cache the compiled script function
                script_func = loaded_func
                script_cache:set(script_name, string.dump(loaded_func))
            end
        else
            -- Unmarshal the string-dumped Lua function
            script_func = loadstring(script_func)
        end

        -- Execute the appropriate Lua script
        script_func()
    else
        ngx.exit(ngx.HTTP_NOT_FOUND)
    end
end

dispatch()
