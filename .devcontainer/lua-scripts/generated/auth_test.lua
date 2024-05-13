-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local auth = require "auth_check"
local mongo = require "mongo_handler"

-- Define the fictional endpoint and parameters for the POST request
local endpoint = 'http://127.0.0.1/sera-test-endpoint'
local post_data = {
    name = 'John Doe',
    email = 'john.doe@example.com',
    age = 28
}

-- Function to perform the POST request
local function make_post_request()
    -- First, check authentication credentials
    auth.check_credentials()

    local httpc = http.new()
    local res, err = httpc:request_uri(endpoint, {
        method = 'POST',
        headers = {
            ['Content-Type'] = 'application/json'
        },
        body = cjson.encode(post_data),
        ssl_verify = false -- Add proper certificate verification as needed
    })

    if not res then
        ngx.log(ngx.ERR, 'Error making POST request: ', err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Check if the request was successful
    if res.status ~= 200 then
        ngx.log(ngx.ERR, 'POST request failed with status: ', res.status)
        ngx.exit(res.status)
    end

    -- Parse the JSON response
    local data, decode_err = cjson.decode(res.body)
    if not data then
        ngx.log(ngx.ERR, 'Error parsing POST response: ', decode_err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end


    
    local mongo_res = mongo.get_admin_settings()
    ngx.say(mongo_res) -- Return the response
    ngx.exit(ngx.HTTP_OK)

    
end

make_post_request()