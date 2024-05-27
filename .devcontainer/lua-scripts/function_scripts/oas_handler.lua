-- Import necessary modules
local cjson = require "cjson.safe"
local oas = require "oas_check"
local mongo = require "mongo_handler"

local function handle_oas(oas_id, host_data)
    local oas_data, err = mongo.get_by_document_id("oas_inventory", oas_id)
    if not oas_data and true then
        ngx.log(ngx.ERR, "Failed to get MongoDB document: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Parse the JSON response
    local oas_data_res = cjson.decode(oas_data)
    if not oas_data_res and oas_data then
        ngx.log(ngx.ERR, "Failed to decode MongoDB response")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local check_oas_res, error_message = oas.check_oas(oas_data_res)

    if not check_oas_res and host_data.sera_config.strict then
        ngx.log(ngx.ERR, error_message)
        ngx.say(error_message)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    return true
end

return {
    handle_oas = handle_oas
}