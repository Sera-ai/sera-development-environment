-- connection_pool.lua
local mongol = require "resty.mongol"
local _M = {}

-- Initialize connection pool variables
local POOL_SIZE = 100
local pool = {}
local idle_timeout = 60000  -- 60 seconds

-- Function to create a new MongoDB connection
local function create_connection()
    local client = mongol.new()
    local ok, err = client:connect("127.0.0.1", 27017)

    if not ok then
        ngx.log(ngx.ERR, "Failed to connect to MongoDB: ", err)
        return nil, err
    end

    return { client = client, timestamp = ngx.now() }
end

-- Function to check if the connection is still alive
local function is_connection_alive(connection)
    local db = connection.client:new_db_handle("admin")
    local res, err = db:cmd({ping = 1})
    if not res then
        ngx.log(ngx.ERR, "MongoDB connection is not alive: ", err)
        return false
    end
    return true
end

-- Function to return a MongoDB connection
function _M.get_connection()
    -- Retrieve an available connection from the pool
    if #pool > 0 then
        local connection = table.remove(pool)
        -- Check if the connection is still alive
        if is_connection_alive(connection) then
            return connection.client
        else
            -- If the connection is not alive, create a new one
            return create_connection().client
        end
    end

    -- Create a new connection if the pool is empty
    return create_connection().client
end

-- Function to return a connection to the pool
function _M.release_connection(connection)
    if #pool < POOL_SIZE then
        table.insert(pool, { client = connection, timestamp = ngx.now() })
    else
        -- If pool is full, don't reuse this connection
        connection:close()
    end
end

-- Function to clean up idle connections
local function cleanup_idle_connections()
    local now = ngx.now()
    for i = #pool, 1, -1 do
        local connection = pool[i]
        -- Check if the connection has been idle for too long
        if (now - connection.timestamp) > (idle_timeout / 1000) then
            table.remove(pool, i)
            connection.client:close()
        end
    end
end

-- Schedule the cleanup function to run periodically
local function schedule_cleanup()
    local ok, err = ngx.timer.every(idle_timeout / 1000, cleanup_idle_connections)
    if not ok then
        ngx.log(ngx.ERR, "Failed to schedule cleanup: ", err)
    end
end

schedule_cleanup()

return _M
