local mongo = require("mongo")
local _M = {}

-- Initialize connection pool variables
local POOL_SIZE = 100
local pool = {}
local idle_timeout = 60000  -- 60 seconds

-- Function to create a new MongoDB connection
local function create_connection()
    local client = mongo.Client("mongodb://sera-mongodb.sera-namespace.svc.cluster.local:27017")

    if not client then
        local err = "Failed to connect to MongoDB"
        ngx.log(ngx.ERR, err)
        return nil, err
    end

    if client then
        ngx.log(ngx.ERR, "MONGO CONNECTED")
    end

    return { client = client, timestamp = ngx.now() }
end

-- Function to check if the connection is still alive
local function is_connection_alive(connection)
    local ok, err = pcall(function()
        local db = connection.client:getDatabase("admin")
        local res = db:runCommand({ping = 1})
        return res.ok == 1
    end)
    if not ok then
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
            return connection.client, nil
        else
            -- If the connection is not alive, create a new one
            local conn, err = create_connection()
            return conn and conn.client or nil, err
        end
    end

    -- Create a new connection if the pool is empty
    local conn, err = create_connection()
    return conn and conn.client or nil, err
end

-- Function to return a connection to the pool
function _M.release_connection(connection)
    if #pool < POOL_SIZE then
        table.insert(pool, { client = connection, timestamp = ngx.now() })
    else
        -- If pool is full, don't reuse this connection
        connection:disconnect()
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
            connection.client:disconnect()
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
