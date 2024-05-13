-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local auth = require "auth_check"

-- Function to perform the POST request
local function auth_test()
    -- First, check authentication credentials
    auth.check_credentials()
    
    ngx.say("authenticated") -- Return the response
    ngx.exit(ngx.HTTP_OK)

    
end

auth_test()