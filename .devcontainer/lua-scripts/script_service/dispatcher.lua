-- dispatcher.lua
local cjson = require "cjson.safe"  -- Safe version that handles errors
local script_cache = ngx.shared.script_cache
local mapper = require "script_mapper"

local function get_mapping(path)
    local script_mapping = ngx.shared.script_mapping
    local value = script_mapping:get(path)
    if not value then
        ngx.log(ngx.ERR, "Mapping not found")
        return cjson.decode('{"filename": "default.lua"}')
    end

    local data = cjson.decode(value)
    if not data then
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say('{"error": "Failed to decode stored mapping"}')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if not data.filename or not data.document_id then
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say('{"error": "Decoded mapping does not contain required fields"}')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    return data
end

local function dispatch()
    
    ngx.var.lua_start_time = ngx.now()

    local request_host = ngx.var.host
    local request_uri = ngx.var.uri
    local request_method = ngx.var.request_method  -- "GET", "POST", etc.

    -- Create a unique key by combining the request URI and method
    local key = request_host .. ":" .. request_uri .. ":" .. request_method

    -- Get the appropriate script name using the mapper and cache mechanism
    local script_name = get_mapping(key)

    if script_name then
        
        -- Retrieve the compiled script function from the cache
        local script_func = script_cache:get(script_name.filename)

        if not script_func then
            ngx.log(ngx.ERR, script_name.filename)
            local script_path = "/etc/nginx/lua-scripts/generated/" .. script_name.filename
            local loaded_func, err = loadfile(script_path)
            if not loaded_func then
                ngx.log(ngx.ERR, "Failed to load script: ", err)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            else
                -- Cache the compiled script function directly
                script_func = loaded_func()
                script_cache:set(script_name.filename, script_func)  -- Adjust depending on your Lua environment
            end
        end
        -- Execute the appropriate Lua script
        script_func.make_request(script_name)
    else
        ngx.exit(ngx.HTTP_NOT_FOUND)
    end
end

dispatch()
