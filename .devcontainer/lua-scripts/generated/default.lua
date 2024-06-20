-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local learning_mode = require "learning_mode"
local request_data = require "request_data"
local mongo_handler = require "mongo_handler"
local ngx = ngx

-- Connection pool settings
local httpc = http.new()
httpc:set_keepalive(60000, 100) -- keep connections alive for 60 seconds, max 100 connections



-- Function to handle the response
local function handle_response(res, host)
    if not res then
        ngx.log(ngx.ERR, 'Error making request')
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if res.status >= 400 then
        ngx.log(ngx.ERR, 'Request failed with status: ', res.status)
        ngx.status = res.status
        ngx.say(res.body)
        ngx.thread.spawn(learning_mode.log_request, res, host)
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
    ngx.thread.spawn(learning_mode.log_request, res, host)
end

-- Function to perform the request
local function make_request()
    ngx.var.proxy_script_start_time = ngx.now()

    local db_entry_host = nil
    ngx.log(ngx.ERR, ngx.var.host)
    local query = { hostname = ngx.var.host }
    local sera_hosts_json, err = mongo_handler.get_settings("sera_hosts", query)

    if err then
        ngx.log(ngx.ERR, err)
    end

    if sera_hosts_json then
        local sera_hosts = cjson.decode(sera_hosts_json)
        local protocol = sera_hosts.sera_config.https and "https://" or "http://"
        db_entry_host = protocol .. sera_hosts.frwd_config.host .. ":" .. sera_hosts.frwd_config.port
    end

    if not db_entry_host then
        ngx.log(ngx.ERR, 'No sera_hosts entry found for host: ', ngx.var.host)
    end
    
    local headers, target_url = request_data.extract_headers_and_url(db_entry_host)

    local method = ngx.var.request_method
    local body = request_data.get_request_body(method)

    ngx.var.proxy_start_time = ngx.now()

    ngx.log(ngx.ERR, "Making request to: ", target_url)

    local query_params = ngx.req.get_uri_args()

    local res, err = httpc:request_uri(target_url, {
        method = method,
        headers = headers,
        body = body,
        query = query_params,
        ssl_verify = false -- Add proper certificate verification as needed
    })

    if err then
        ngx.log(ngx.ERR, err)
    end

    ngx.var.proxy_finish_time = ngx.now()

    handle_response(res, ngx.var.host)
end

return {
    make_request = make_request
}
