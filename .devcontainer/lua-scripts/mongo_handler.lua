-- mongo_handler.lua
-- Function to clean up non-serializable data types and convert ObjectIDs
local function strip_and_convert_mongo_fields(tbl)
    local result = {}

    for k, v in pairs(tbl) do
        local value_type = type(v)

        if value_type == "string" or value_type == "number" or value_type == "boolean" then
            result[k] = v
        elseif value_type == "table" then
            -- Check for MongoDB ObjectID
            if v.oid and type(v.oid) == "string" then
                result[k] = v:to_hex() -- Convert to a readable hexadecimal string
            else
                result[k] = strip_and_convert_mongo_fields(v) -- Recursively handle other nested tables
            end
        end
    end

    return result
end

local function with_retries(fn, max_retries)
    local retries = 0
    while retries < max_retries do
        local ok, result_or_err = pcall(fn)
        if ok then
            return result_or_err
        end
        retries = retries + 1
        ngx.log(ngx.ERR, "MongoDB query failed, retrying: ", result_or_err)
    end
    return nil, "Failed after " .. max_retries .. " retries"
end

local function convert_hex_string_to_normal(str)
    return (str:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function get_settings(collection, query)
    ngx.log(ngx.ERR, "starting to connect")

    local mongo_pool = require "connection_pool"
    local cjson = require "cjson"

    return with_retries(function()
        -- Acquire a MongoDB connection from the pool
        local client, err = mongo_pool.get_connection()
        if not client then
            ngx.log(ngx.ERR, "Unable to obtain MongoDB connection: ", err)
            return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        -- Proceed with MongoDB operations
        local db = client:new_db_handle("Sera")
        local col = db:get_col(collection)
        local result, err = col:find_one(query)
        
        if not result then
            ngx.log(ngx.ERR, "MongoDB find error: ", err)
            mongo_pool.release_connection(client)
            return ngx.exit(ngx.HTTP_NOT_FOUND)
        end

        -- Release the connection back to the pool
        mongo_pool.release_connection(client)

        -- Serialize the cleaned result to JSON
        return cjson.encode(strip_and_convert_mongo_fields(result))
    end, 3)  -- Retry up to 3 times
end

local function get_by_document_id(collection, document_id)
    ngx.log(ngx.ERR, "starting to connect")

    local mongo_pool = require "connection_pool"
    local cjson = require "cjson"
    local object_id = require "resty.mongol.object_id"

    return with_retries(function()
        -- Acquire a MongoDB connection from the pool
        local client, err = mongo_pool.get_connection()
        if not client then
            ngx.log(ngx.ERR, "Unable to obtain MongoDB connection: ", err)
            return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        -- Proceed with MongoDB operations
        local db = client:new_db_handle("Sera")
        local col = db:get_col(collection)
        local normal_id = convert_hex_string_to_normal(document_id)
        local query = { _id = object_id.new(normal_id) }
        local result, err = col:find_one(query)
        
        if not result then
            ngx.log(ngx.ERR, "MongoDB find error: ", err)
            mongo_pool.release_connection(client)
            return ngx.exit(ngx.HTTP_NOT_FOUND)
        end

        -- Release the connection back to the pool
        mongo_pool.release_connection(client)

        -- Serialize the cleaned result to JSON
        return cjson.encode(strip_and_convert_mongo_fields(result))
    end, 3)  -- Retry up to 3 times
end

-- Return the functions to be used externally
return {
    get_settings = get_settings,
    get_by_document_id = get_by_document_id
}
