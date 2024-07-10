-- mongo_handler.lua
local mongo = require("mongo")
local cjson = require("cjson")
local mongo_pool = require("connection_pool")

-- Function to clean up non-serializable data types and convert ObjectIDs
local function strip_and_convert_mongo_fields(tbl)
    local result = {}

    if type(tbl) == "userdata" then
        tbl = tbl:toTable()  -- Convert userdata to table if possible
    end

    for k, v in pairs(tbl) do
        local value_type = type(v)

        if value_type == "string" or value_type == "number" or value_type == "boolean" then
            result[k] = v
        elseif value_type == "table" then
            -- Check for MongoDB ObjectID
            if v.oid and type(v.oid) == "userdata" then
                result[k] = v:toString()  -- Convert to a readable hexadecimal string
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
    return with_retries(function()
        -- Acquire a MongoDB connection from the pool
        local client, err = mongo_pool.get_connection()
        if not client then
            ngx.log(ngx.ERR, "Unable to obtain MongoDB connection: ", err)
            return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        -- Proceed with MongoDB operations
        local db = client:getDatabase("Sera")
        local col = db:getCollection(collection)
        local result = col:findOne(query):value()
        
        if not result then
            mongo_pool.release_connection(client)
            return nil, "MongoDB find error"
        end

        -- Release the connection back to the pool
        mongo_pool.release_connection(client)

        -- Serialize the cleaned result to JSON
        return cjson.encode(strip_and_convert_mongo_fields(result))
    end, 3)  -- Retry up to 3 times
end

local function get_by_document_id(collection, document_id)
    return with_retries(function()
        -- Acquire a MongoDB connection from the pool
        local client, err = mongo_pool.get_connection()
        if not client then
            ngx.log(ngx.ERR, "Unable to obtain MongoDB connection: ", err)
            return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        -- Proceed with MongoDB operations
        local db = client:getDatabase("Sera")
        local col = db:getCollection(collection)
        local normal_id = convert_hex_string_to_normal(document_id)
        local object_id = mongo.ObjectId(normal_id)
        local query = { _id = object_id }
        local result = col:findOne(query):value()
        
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
