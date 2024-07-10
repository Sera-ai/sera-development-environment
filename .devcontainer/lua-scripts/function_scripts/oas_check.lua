local cjson = require "cjson"
local ngx = ngx

-- Extract request details
local function get_request_details()
    local headers = ngx.req.get_headers()

    return {
        method = ngx.req.get_method(),
        path = ngx.var.uri,
        query = ngx.req.get_uri_args(),
        cookies = ngx.var.cookie,
        headers = headers
    }
end

-- Safely log values, even if they are nil
local function safe_log(label, value)
    if value then
        ngx.log(ngx.ERR, label .. ": " .. tostring(value))
    else
        ngx.log(ngx.ERR, label .. ": nil")
    end
end

-- Validate request against OAS
local function validate_request(oas, request)
    local paths = oas.paths
    local path_spec = paths[request.path]

    if not path_spec then
        return false, "No path found"
    end

    local method_spec = path_spec[request.method:lower()]
    if not method_spec then
        return false, "Method not found"
    end

    local required_params = method_spec.parameters or {}

    -- Use pairs to handle the parameter array more flexibly
    for key, param in pairs(required_params) do
        if param.required then
            if param["in"] == "query" then
                if not request.query[param.name] then
                    return false, "Required query parameter '" .. param.name .. "' not found"
                end
            elseif param["in"] == "header" then
                local headers = request.headers
                local header_value = headers[param.name]
                if not header_value then
                    return false, "Required header '" .. param.name .. "' not found"
                end
            elseif param["in"] == "path" then
                if not ngx.var[param.name] then
                    return false, "Required path parameter '" .. param.name .. "' not found"
                end
            elseif param["in"] == "cookie" then
                if not request.cookies[param.name] then
                    return false, "Required cookie parameter '" .. param.name .. "' not found"
                end
            end
        end
    end

    return true
end

-- Function to validate the response against the OAS
local function validate_response(oas, response)
    local path_spec = oas.paths[ngx.var.uri]
    if not path_spec then
        return false, "No path found in OAS for the given URI"
    end

    local method_spec = path_spec[ngx.req.get_method():lower()]
    if not method_spec then
        return false, "No method found in OAS for the given URI and method"
    end

    local responses = method_spec.responses
    if not responses then
        return false, "No responses found in OAS for the given URI and method"
    end

    local response_spec = responses[tostring(response.status)]
    if not response_spec then
        return false, "No response specification found in OAS for the given status code"
    end

    -- Additional validation logic can be added here, e.g., checking headers, body content, etc.
    
    return true
end


-- Main function to check OAS and handle response
local function check_oas(oas)
    if not oas then
        return false, "Failed to load OAS"
    end

    local request = get_request_details()
    local valid, error_message = validate_request(oas, request)

    if not valid then
        ngx.log(ngx.ERR, "Request validation failed: " .. error_message)
        return false, "Invalid request: " .. error_message
    end

    return true
end

-- Return the check_oas function for other uses if needed
return {
    check_oas = check_oas,
    validate_response = validate_response
}
