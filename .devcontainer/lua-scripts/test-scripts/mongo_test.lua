-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local mongo = require "mongo_handler"

-- Function to perform the POST request
local function make_post_request()
    
    local mongo_res = mongo.get_settings("builder_inventory", {_id: "662b0fcc692d346447927182"})
    ngx.say(mongo_res) -- Return the response
    ngx.exit(ngx.HTTP_OK)

    
end

make_post_request()