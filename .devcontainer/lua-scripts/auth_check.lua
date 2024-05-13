-- auth_check.lua
local mime = require "mime"

-- Base64 decoding using LuaSocket's `mime` module
local function decode_base64(input)
    if not input or input == "" then
        return ""
    end

    -- Decode input via the mime.b64 function
    local ok, decoded = pcall(mime.unb64, input)
    if not ok then
        return ""
    end

    return decoded
end

-- Ensure this function is part of the returned module
local function authenticate(username, password)
    local valid_username = "admin"
    local valid_password = "admin"

    return username == valid_username and password == valid_password
end

local function check_credentials()
    local auth_header = ngx.var.http_authorization
    if not auth_header then
        ngx.header["WWW-Authenticate"] = 'Basic realm="Restricted Area"'
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    local encoded_credentials = auth_header:match("^Basic%s+(.+)$")
    if not encoded_credentials or encoded_credentials == "" then
        ngx.header["WWW-Authenticate"] = 'Basic realm="Restricted Area"'
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    local decoded_credentials = decode_base64(encoded_credentials)
    if not decoded_credentials or decoded_credentials == "" then
        ngx.header["WWW-Authenticate"] = 'Basic realm="Restricted Area"'
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    local username, password = decoded_credentials:match("^(.-):(.-)$")
    if not username or not password or not authenticate(username, password) then
        ngx.header["WWW-Authenticate"] = 'Basic realm="Restricted Area"'
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
end

return {
    check_credentials = check_credentials
}
