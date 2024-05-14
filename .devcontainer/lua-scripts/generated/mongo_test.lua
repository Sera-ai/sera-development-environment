-- request script (script_func)

-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local mongo = require "mongo_handler"

-- Function to perform the POST request
local function make_request(document_id)
    local mongo_res_json, err = mongo.get_by_document_id("builder_inventory", document_id)
    if not mongo_res_json then
        ngx.log(ngx.ERR, "Failed to get MongoDB document: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Parse the JSON response
    local mongo_res = cjson.decode(mongo_res_json)
    if not mongo_res then
        ngx.log(ngx.ERR, "Failed to decode MongoDB response")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Extract the "enabled" field
    local enabled = mongo_res.enabled
    local comparison = (enabled == true)
    -- Return the "enabled" field in the response
    ngx.say(comparison)
    ngx.exit(ngx.HTTP_OK)
end

return {
    make_request = make_request
}
