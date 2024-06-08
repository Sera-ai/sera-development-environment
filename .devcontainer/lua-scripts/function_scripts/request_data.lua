local ngx = ngx

-- Function to extract headers and target URL
local function extract_headers_and_url()
    local headers = ngx.req.get_headers()
    local target_url = headers["X-Forwarded-For"]

    if not target_url then
        ngx.log(ngx.ERR, 'No X-Forwarded-For header specified')
        ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    -- Append the request URI to the target URL to preserve the resource path
    local uri = ngx.var.uri
    target_url = target_url .. uri

    -- Add cookies to headers if present
    local cookies = ngx.var.http_cookie
    if cookies then
        headers["Cookie"] = cookies
    end

    return headers, target_url
end

-- Function to get request body for applicable methods
local function get_request_body(method)
    if method == "POST" or method == "PUT" or method == "PATCH" then
        ngx.req.read_body()
        return ngx.req.get_body_data()
    end
    return nil
end



return {
    get_request_body = get_request_body,
    extract_headers_and_url = extract_headers_and_url
}