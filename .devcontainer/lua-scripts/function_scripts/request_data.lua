local ngx = ngx
local cjson = require "cjson.safe"

-- Function to extract headers and target URL
local function extract_headers_and_url(given_url)
    local headers = ngx.req.get_headers()
    local target_url

    if given_url then
        target_url = given_url
    end
    
    if not given_url then
        target_url = headers["X-Forwarded-For"]
    end

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


local function mergeTables(t1, t2)
    local mergedTable = {}
    -- Copy all key-value pairs from the first table
    for k, v in pairs(t1) do
        if type(v) ~= "function" then
            mergedTable[k] = v
        end
    end
    -- Copy key-value pairs from the second table only if the key does not exist in the first table and the value is not a function
    for k, v in pairs(t2) do
        if mergedTable[k] == nil and type(v) ~= "function" then
            mergedTable[k] = v
        end
    end
    return mergedTable
end

local function update_json_values(original, data, replacements, sera_res)
    if type(data) == "table" then
        for key, value in pairs(data) do
            if type(value) == "table" then
                update_json_values(original, value, replacements, sera_res)
            else
                ngx.log(ngx.ERR, "replacements: ", key)
                ngx.log(ngx.ERR, "replacements: ", cjson.encode(replacements))
                ngx.log(ngx.ERR, "replacements: ", replacements[key])
                ngx.log(ngx.ERR, "replacements: ", cjson.encode(original))

                local val_res = split(replacements[key], ".")
                ngx.log(ngx.ERR, "val_res: ", cjson.encode(val_res))
                if val_res[1] then
                    if string.find(val_res[1], "body") then
                        data[key] = original[replacements[val_res[2]]] or value
                    else
                        data[key] = sera_res[val_res[1]][val_res[2]] or value
                    end
                end
            end
        end
    end
end

function split(str, delimiter)
    local result = {}
    local from = 1
    -- Escape the delimiter if it's a special character
    local delim_pattern = delimiter:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
    local delim_from, delim_to = string.find(str, delim_pattern, from)
    while delim_from do
        table.insert(result, string.sub(str, from , delim_from-1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim_pattern, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

return {
    get_request_body = get_request_body,
    extract_headers_and_url = extract_headers_and_url,
    mergeTables = mergeTables,
    update_json_values = update_json_values
}