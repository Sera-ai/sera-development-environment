-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local learning_mode = require "learning_mode"
local request_data = require "request_data"
local ngx = ngx

-- Connection pool settings
local httpc = http.new()
httpc:set_keepalive(60000, 100) -- keep connections alive for 60 seconds, max 100 connections



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

-- Function to perform the request
local function make_request()
    ngx.var.proxy_script_start_time = ngx.now()

    local headers, target_url = request_data.extract_headers_and_url()
    local method = ngx.var.request_method
    local body = request_data.get_request_body(method)

    ngx.var.proxy_start_time = ngx.now()

    local res, err = httpc:request_uri(target_url, {
        method = method,
        headers = headers,
        body = body,
        ssl_verify = false -- Add proper certificate verification as needed
    })

    if err then
        ngx.log(ngx.ERR, err)
    end

    ngx.var.proxy_finish_time = ngx.now()

    handle_response(res)
end

return {
    make_request = make_request
}
