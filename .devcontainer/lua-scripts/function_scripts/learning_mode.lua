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

    local function is_header_auth()
        return headers["X-Auth-Token"] ~= nil
    end

    local function is_oauth()
        local auth_header = headers["Authorization"]
        if auth_header then
            -- Convert both to lower case for case-insensitive comparison
            auth_header = auth_header:lower()
            return auth_header:find("bearer ") == 1
        end
        return false
    end

    local function is_api_key()
        -- Check for a custom header that you use for API keys
        return headers["X-Api-Key"] ~= nil
    end

    local function is_saml()
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        if not body_data then
            return false
        end
        return body_data:find("<samlp:AuthnRequest") or body_data:find("<samlp:Response")
    end

    local function is_jwt(token)
        -- Check if the token has three parts separated by dots
        local parts = {}
        for part in string.gmatch(token, "[^.]+") do
            table.insert(parts, part)
        end
        return #parts == 3
    end

    local auth_type

    if is_header_auth() then
        auth_type = "Header Authentication"
    elseif is_oauth() then
        local auth_header = headers["Authorization"]
        auth_header = auth_header:lower()

        local token = auth_header:match("bearer%s+(.+)")
        if token then
            if is_jwt(token) then
                auth_type = "JWT"
            else
                auth_type = "OAuth (Bearer Token)"
            end
        else
            auth_type = "Unknown Bearer Token"
        end
    elseif is_saml() then
        auth_type = "SAML"
    elseif is_api_key() then
        auth_type = "API Key"
    else
        auth_type = nil
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
        ssl_analytics = {
            protocol = ngx.var.ssl_protocol,
            cipher = ngx.var.ssl_cipher,
            client_cert = ngx.var.ssl_client_cert,
            client_raw_cert = ngx.var.ssl_client_raw_cert,
            client_serial = ngx.var.ssl_client_serial,
            client_s_dn = ngx.var.ssl_client_s_dn,
            client_i_dn = ngx.var.ssl_client_i_dn,
            client_fingerprint = ngx.var.ssl_client_fingerprint,
            client_verify = ngx.var.ssl_client_verify,
            session_id = ngx.var.ssl_session_id,
            session_reused = ngx.var.ssl_session_reused
        },
        session_analytics = {
            ip_address = ngx.var.remote_addr,
            user_agent = ngx.var.http_user_agent,
            auth_type = auth_type,
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