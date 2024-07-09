-- Import necessary modules
local http = require "resty.http"
local cjson = require "cjson.safe"
local learning_mode = require "learning_mode"
local request_data = require "request_data"
local oas_check = require "oas_check"
local oas_handler = require "oas_handler"
local mongo = require "mongo_handler"
local ngx = ngx

-- Dynamic imports

-- Connection pool settings
local httpc = http.new()
httpc:set_keepalive(60000, 100) -- keep connections alive for 60 seconds, max 100 connections

local function async_after_tasks()
    
end

local function send_response(sera_res, res)
    -- -- Set response headers
    -- for k, v in pairs(res.headers) do
    --     ngx.header[k] = v
    -- end

    if sera_res.headers then
        for k, v in pairs(sera_res.headers) do
            ngx.header[k] = v
        end    
    end
    
    -- Return the response body
    -- Set the status code
    ngx.status = sera_res.status or res.status
    -- Encode the body
    local body = cjson.encode(sera_res.body)

    -- Set correct Content-Length and Content-Type headers
    ngx.header["Content-Length"] = #body

    -- Send the body
    ngx.say(body)

    ngx.eof()

    -- Spawn a worker thread to handle logging asynchronously
    ngx.thread.spawn(learning_mode.log_request, res)

    
end


local function sera_response_middleware(res, requestDetails)
    local response_body = res.body
    local response_json = cjson.decode(response_body)
    local body_data = ngx.req.get_body_data()
    local body_json = cjson.decode(body_data)

    -- Unsupported type: Status Codes
    local headers_content_type = res.headers["content-type"]
    local headers_Connection = res.headers["Connection"]
    local headers_content_length = res.headers["content-length"]
    local headers_Keep_Alive = res.headers["Keep-Alive"]
    local headers_Date = res.headers["Date"]
    local headers_access_control_allow_origin = res.headers["access-control-allow-origin"]

    -- Collecting values to be used for replacements
    local replacement_values = {}
    if type(response_json) == "table" and #response_json == 0 then
        for key, value in pairs(response_json) do
            replacement_values[key] = value
        end
    end

    local sera_res = {
        ["headers"] = {
            ["content-type"] = headers_content_type,
            ["Connection"] = headers_Connection,
            ["content-length"] = headers_content_length,
            ["Keep-Alive"] = headers_Keep_Alive,
            ["Date"] = headers_Date,
            ["access-control-allow-origin"] = headers_access_control_allow_origin
        }
    }

    sera_res.headers = request_data.mergeTables(sera_res.headers, res.headers)

    -- Update JSON values in the response body
    if type(response_json) == "table" then
        if #response_json > 0 then
            -- Handle JSON array case
            for i, obj in ipairs(response_json) do
                request_data.update_json_values(obj, replacement_values)
            end
        else
            -- Handle JSON object case
            request_data.update_json_values(response_json, replacement_values)
        end
    end

    sera_res.body = response_json

    send_response(sera_res, res)
end

-- Function to handle the response
local function handle_response(res, requestDetails)
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

    sera_response_middleware(res, requestDetails)
end

local function send_request(requestDetails)
    local target_url = requestDetails.request_target_url
    local headers = requestDetails.header or {}
    local cookie = requestDetails.cookie or {}
    local query = requestDetails.query or {}
    local body = requestDetails.body or {}

    -- Append query parameters if they exist
    if next(query) then
        local query_string = ngx.encode_args(query)
        target_url = target_url .. "?" .. query_string
    end

    ngx.var.proxy_start_time = ngx.now()

    local res, err = httpc:request_uri(target_url, {
        method = ngx.var.request_method,
        headers = headers,
        query = query,
        body = cjson.encode(body),
        ssl_verify = false -- Add proper certificate verification as needed
    })

    ngx.var.proxy_finish_time = ngx.now()

    handle_response(res,requestDetails)
end


local function sera_request_middleware(request_target_url)
    ngx.req.read_body()
    local body_data = ngx.req.get_body_data()
    local body_json = cjson.decode(body_data)

    



    local requestDetails = {
        request_target_url = request_target_url,
        
    }
    send_request(requestDetails)
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

        local protocol = host_data.sera_config.https and "https://" or "http://"
        local db_entry_host = protocol .. host_data.frwd_config.host .. ":" .. host_data.frwd_config.port

        local oas_res, err = oas_handler.handle_oas(data.oas_id, host_data)
     
        if oas_res then
            ngx.var.proxy_script_start_time = ngx.now()

            local headers, target_url = request_data.extract_headers_and_url(db_entry_host)
        
            sera_request_middleware(target_url)
        end
    else
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

return {
    make_request = make_request
}