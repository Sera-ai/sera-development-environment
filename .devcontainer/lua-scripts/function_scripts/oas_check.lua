local cjson = require "cjson"
local ngx = ngx

-- Extract request details
local function get_request_details()
    return {
        method = ngx.req.get_method(),
        path = ngx.var.uri,
        args = ngx.req.get_uri_args()
    }
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
    for _, param in ipairs(required_params) do
        if param.required and not request.args[param.name] then
            return false, "Required parameter '" .. param.name .. "' not found"
        end
    end

    return true
end

-- Main
local function check_oas(oas)
    if not oas then
        return false, "Failed to load OAS"
    end

    local request = get_request_details()
    local valid, error_message = validate_request(oas, request)

    if not valid then
        return false, "Invalid request: " .. error_message
    end
    return valid, error_message
end
-- Continue with normal processing

return {
    check_oas = check_oas
}
