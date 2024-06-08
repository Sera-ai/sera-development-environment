-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local learning_mode = require "learning_mode"
local request_data = require "request_data"
local oas_check = require "oas_check"
local oas_handler = require "oas_handler"
local mongo = require "mongo_handler"
local ngx = ngx

-- Connection pool settings
local httpc = http.new()
httpc:set_keepalive(60000, 100) -- keep connections alive for 60 seconds, max 100 connections

local function send_response(res)
    -- Set response headers
    for k, v in pairs(res.headers) do
        ngx.header[k] = v
    end

    -- Return the response body
    ngx.status = res.status
    ngx.say(res.body)
    ngx.eof()

    -- Spawn a worker thread to handle logging asynchronously
    ngx.thread.spawn(learning_mode.log_request, res)
end

local function sera_response_middleware(res)
    
    send_response(res)
end

-- Function to handle the response
local function handle_response(res)
    if not res then
        ngx.log(ngx.ERR, 'Error making request')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if res.status >= 400 then
        ngx.log(ngx.ERR, 'Request failed with status: ', res.status)
        ngx.status = res.status
        ngx.say(res.body)
        return ngx.exit(res.status)
    end

    local oas = cjson.decode(ngx.var.oas_data)
    local host_data = cjson.decode(ngx.var.host_data)
    -- Validate the response against the OAS
    local valid, error_message = oas_check.validate_response(oas, res)
    if not valid and host_data.sera_config.strict then
        ngx.log(ngx.ERR, "Response validation failed: " .. error_message)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Invalid response: " .. error_message)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    sera_response_middleware(res)
end

local function send_request(target_url, headers, method, body)
    ngx.var.proxy_start_time = ngx.now()

    local res, err = httpc:request_uri(target_url, {
        method = method,
        headers = headers,
        body = body,
        ssl_verify = false -- Add proper certificate verification as needed
    })

    ngx.var.proxy_finish_time = ngx.now()

    handle_response(res)
end


local function sera_request_middleware(target_url, headers, method, body)

    send_request(target_url, headers, method, body)
end

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

        ngx.var.host_data = cjson.encode(host_data)

        local oas_res, err = oas_handler.handle_oas(data.oas_id, host_data)
     
        if oas_res then
            ngx.var.proxy_script_start_time = ngx.now()

            local headers, target_url = request_data.extract_headers_and_url()
            local method = ngx.var.request_method
            local body = request_data.get_request_body(method)
        
            sera_request_middleware(target_url, headers, method, body)
        end
    else
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

return {
    make_request = make_request
}