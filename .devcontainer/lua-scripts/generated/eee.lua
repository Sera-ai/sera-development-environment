-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local auth = require "auth_check"
local mongo = require "mongo_handler"

-- Function to perform the POST request
local function eee(data)
    -- First, check authentication credentials
    auth.check_credentials()
    
    local oas_data, err = mongo.get_by_document_id("oas_inventory", data.oas_id)
    if not oas_data then
        ngx.log(ngx.ERR, "Failed to get MongoDB document: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Parse the JSON response
    local oas_data_res = cjson.decode(oas_data)
    if not oas_data_res then
        ngx.log(ngx.ERR, "Failed to decode MongoDB response")
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Return the "enabled" field in the response
    ngx.say(oas_data_res)
    ngx.exit(ngx.HTTP_OK)

    
end

eee()