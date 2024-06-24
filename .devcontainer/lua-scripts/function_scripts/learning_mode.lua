-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local ngx = ngx

local function extract_hostname(url)
    local patterns = {
        "https://([%w%.%-]+:%d+)", -- Matches https://hostname:port
        "https://([%w%.%-]+)",     -- Matches https://hostname
        "http://([%w%.%-]+:%d+)",  -- Matches http://hostname:port
        "http://([%w%.%-]+)",      -- Matches http://hostname
        "^([%w%.%-]+)$"            -- Matches IP or hostname without protocol
    }

    for _, pattern in ipairs(patterns) do
        local hostname = url:match(pattern)
        if hostname then
            return hostname
        end
    end

    return url -- Fallback in case no pattern matches
end

-- Function to perform the logging
local function log_request(res, host)


    local log_httpc = http.new()
    log_httpc:set_timeout(10000) -- Set a very short timeout

    local response_time = ngx.var.proxy_finish_time - ngx.var.nginx_start_time

    -- Ensure all variables are not nil
    local headers = ngx.req.get_headers() or {}
    local target_url = headers["X-Forwarded-For"] or host
    local method = ngx.var.request_method or "unknown"

    if string.upper(method) == "OPTIONS" then
        return
    end

    ngx.log(ngx.ERR, "Logging analytics for URL: ", target_url)


    local body = {}
    if method == "POST" or method == "PUT" or method == "PATCH" then
        ngx.req.read_body()
        body = ngx.req.get_body_data()
    end

    -- Safely extract data from the res object
    local res_status = res.status or "unknown"
    local res_headers = res.headers or {}
    local res_body = res.body or {}

    local log_body = cjson.encode({
        hostname = extract_hostname(target_url),
        path = ngx.var.uri or "unknown",
        method = method,
        response_time = ngx.var.request_time * 1000,
        ts = ngx.now(),
        ts_breakdown = {
            init = (ngx.var.lua_start_time - ngx.var.nginx_start_time) * 1000,
            dispatch = (ngx.var.proxy_script_start_time - ngx.var.lua_start_time) * 1000,
            lua_script = (ngx.var.proxy_start_time - ngx.var.proxy_script_start_time) * 1000,
            proxy_time = (ngx.var.proxy_finish_time - ngx.var.proxy_start_time) * 1000
        },
        session_analytics = {
            ip_address = ngx.var.remote_addr,
            user_agent = ngx.var.http_user_agent,
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
    local log_res, log_err = log_httpc:request_uri("http://127.0.0.1:12060/analytics/new", {
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

return {
    log_request = log_request
}