-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local ngx = ngx

-- Function to perform the request
local function make_request()
    local httpc = http.new()

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

    -- Perform the request
    local res, err = httpc:request_uri(target_url, {
        method = method,
        headers = headers,
        body = body,
        ssl_verify = false -- Add proper certificate verification as needed
    })

    ngx.log(ngx.ERR, target_url)

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

    -- Perform logging after response is sent
    ngx.timer.at(0, function()
        -- Place your logging/analytics code here
        ngx.log(ngx.INFO, "Logging analytics for URL: ", target_url)
        -- Example: log to a file, send to an external service, etc.
    end)
end

return {
    make_request = make_request
}