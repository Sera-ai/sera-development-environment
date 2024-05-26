-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local auth = require "auth_check"
local oas = require "oas_check"
local oas_handler = require "oas_handler"
local mongo = require "mongo_handler"

-- Function to perform the POST request
local function make_request(data)
    -- First, check authentication credentials
    if data then
        local host_data_raw = mongo.get_by_document_id("sera_hosts", data.document_id)

        -- Parse the JSON response
        local host_data = cjson.decode(host_data_raw)
        if not host_data then
            ngx.log(ngx.ERR, "Failed to decode MongoDB response")
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        local oas_res, err = oas_handler.handle_oas(data.oas_id, host_data)
     
        ngx.say(oas_res)
        ngx.exit(ngx.HTTP_OK)

    else
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)

    end
    
end

return {
    make_request = make_request
}
