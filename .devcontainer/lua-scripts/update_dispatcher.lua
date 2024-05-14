-- update_dispatcher.lua
local cjson = require "cjson.safe"  -- Safe version that handles errors

local function update_mapping()
    ngx.req.read_body()  -- Explicitly read the POST body
    local body = ngx.req.get_body_data()
    if not body then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"error": "No data provided"}')
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    local data = cjson.decode(body)
    if not data or not data.path or not data.filename or not data.document_id then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"error": "Invalid JSON data"}')
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    -- Fetch the shared dictionary
    local script_mapping = ngx.shared.script_mapping
    local value = cjson.encode({filename = data.filename, document_id = data.document_id})
    local success, err = script_mapping:set(data.path, value)
    if not success then
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say('{"error": "Failed to update mapping: ' .. tostring(err) .. '"}')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    ngx.say('{"success": "'..script_mapping:get(data.path)..'"}')
end

return {
    update_mapping = update_mapping
}
