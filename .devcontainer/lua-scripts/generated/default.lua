-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local ngx = ngx

-- Connection pool settings
local httpc = http.new()
httpc:set_keepalive(60000, 100) -- keep connections alive for 60 seconds, max 100 connections

-- Function to perform the logging
local function log_request(headers, target_url, method, body, res, response_time)
    ngx.log(ngx.ERR, "Logging analytics for URL: ", target_url)

    local log_httpc = http.new()
    log_httpc:set_timeout(1) -- Set a very short timeout

    -- Ensure all variables are not nil
    headers = headers or {}
    target_url = target_url or "unknown"
    method = method or "unknown"
    body = body or {}

    -- Safely extract data from the res object
    local res_status = res.status or "unknown"
    local res_headers = res.headers or {}
    local res_body = res.body or {}

    local log_body = cjson.encode({
        hostname = headers["X-Forwarded-For"],
        path = ngx.var.uri or "unknown",
        method = method,
        response_time = response_time * 100,
        ts = ngx.now(),
        ts_breakdown = {
            init = (ngx.var.lua_start_time - ngx.var.nginx_start_time) * 100,
            dispatch = (ngx.var.proxy_script_start_time - ngx.var.lua_start_time) * 100,
            lua_script = (ngx.var.proxy_start_time - ngx.var.proxy_script_start_time) * 100,
            proxy_time = (ngx.var.proxy_finish_time - ngx.var.proxy_start_time) * 100
        },
        request = {
            headers = headers,
            query = ngx.req.get_uri_args() or {},
            cookies = ngx.var.cookie or {},
            body = cjson.decode(body) or body
        },
        response = {
            status = res_status,
            statusText = "OK",
            headers = res_headers,
            data = cjson.decode(res_body) or res_body
        }
    })

    ngx.log(ngx.ERR, log_body)

    -- Perform the request with a short timeout
    local log_res, log_err = log_httpc:request_uri("http://127.0.0.1:12050/analytics/new", {
        method = "POST",
        headers = {
            ['Content-Type'] = 'application/json'
        },
        body = log_body,
        ssl_verify = false -- Add proper certificate verification as needed
    })

    -- Since we set a short timeout, we don't care about the response
    if not log_res then
        ngx.log(ngx.ERR, 'Error logging analytics: ', log_err)
    end
end

-- Function to perform the request
local function make_request()

    ngx.var.proxy_script_start_time = ngx.now()

    -- Extract the X-Forwarded-For header
    local headers = ngx.req.get_headers()
    local target_url = headers["X-Forwarded-For"]

    if not target_url then
        ngx.log(ngx.ERR, 'No X-Forwarded-For header specified')
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    -- Append the request URI to the target URL to preserve the resource path
    local uri = ngx.var.uri
    target_url = target_url .. uri

    -- Get request method
    local method = ngx.var.request_method

    -- Add cookies to headers if present
    local cookies = ngx.var.http_cookie
    if cookies then
        headers["Cookie"] = cookies
    end

    -- Get request body for methods that may have a body
    local body = nil
    if method == "POST" or method == "PUT" or method == "PATCH" then
        ngx.req.read_body()
        body = ngx.req.get_body_data()
    end

    ngx.var.proxy_start_time = ngx.now()

    -- Perform the request
    local res, err = httpc:request_uri(target_url, {
        method = method,
        headers = headers,
        body = body,
        ssl_verify = false -- Add proper certificate verification as needed
    })

    ngx.var.proxy_finish_time = ngx.now()
    
    local response_time = ngx.var.proxy_finish_time - ngx.var.nginx_start_time

    if not res then
        ngx.log(ngx.ERR, 'Error making request: ', err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- Check if the request was successful
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
    ngx.thread.spawn(log_request, headers, target_url, method, body, res, response_time)
end

return {
    make_request = make_request
}
