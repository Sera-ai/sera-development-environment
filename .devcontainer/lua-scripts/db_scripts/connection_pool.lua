-- connection_pool.lua
local mongol = require "resty.mongol"
local _M = {}

-- Initialize connection pool variables
local POOL_SIZE = 10
local pool = {}

-- Function to return a MongoDB connection
function _M.get_connection()
    -- Retrieve an available connection from the pool
    if #pool > 0 then
        return table.remove(pool)
    end

    -- Create a new connection if the pool is empty
    local client = mongol.new()
    local ok, err = client:connect("127.0.0.1", 27017)

    if not ok then
        ngx.log(ngx.ERR, "Failed to connect to MongoDB: ", err)
        return nil, err
    end

    return client
end

-- Function to return a connection to the pool
function _M.release_connection(connection)
    if #pool < POOL_SIZE then
        table.insert(pool, connection)
    else
        -- If pool is full, don't reuse this connection
        connection:close()
    end
end

return _M
