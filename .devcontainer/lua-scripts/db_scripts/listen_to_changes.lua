local mongo_handler = require("mongo_handler")
local cjson = require("cjson")
local ngx_cache = ngx.shared.oas_cache

-- Function to update cache based on change event
local function update_cache(change_event)
    local document_key = change_event.documentKey._id
    local full_document = change_event.fullDocument

    if change_event.ns.coll == "sera_hosts" then
        local hostname = full_document.hostname
        local oas_spec_id = full_document.oas_spec

        -- Retrieve the corresponding document from the oas_inventory collection
        local oas_inventory_json, err = mongo_handler.get_by_document_id("oas_inventory", oas_spec_id)
        if not oas_inventory_json then
            ngx.log(ngx.ERR, "Failed to retrieve oas_inventory document: ", err)
        else
            -- Cache the document in the shared dictionary
            local cache_key = hostname
            local cache_value = oas_inventory_json
            local success, err, forcible = ngx_cache:set(cache_key, cache_value)
            if not success then
                ngx.log(ngx.ERR, "Failed to set cache for key ", cache_key, ": ", err)
            elseif forcible then
                ngx.log(ngx.WARN, "Cache for key ", cache_key, " was forcibly overwritten")
            end
        end
    elseif change_event.ns.coll == "oas_inventory" then
        -- Retrieve the corresponding sera_hosts document and update cache
        local query = { oas_spec = document_key }
        local sera_hosts_json, err = mongo_handler.get_settings("sera_hosts", query)
        if not sera_hosts_json then
            ngx.log(ngx.ERR, "Failed to retrieve sera_hosts for oas_spec: ", err)
        else
            local sera_hosts = cjson.decode(sera_hosts_json)
            for _, host_entry in ipairs(sera_hosts) do
                local hostname = host_entry.hostname
                local cache_key = hostname
                local cache_value = cjson.encode(full_document)
                local success, err, forcible = ngx_cache:set(cache_key, cache_value)
                if not success then
                    ngx.log(ngx.ERR, "Failed to set cache for key ", cache_key, ": ", err)
                elseif forcible then
                    ngx.log(ngx.WARN, "Cache for key ", cache_key, " was forcibly overwritten")
                end
            end
        end
    end
end

-- Function to listen to change streams
local function listen_to_changes()
    local mongo_pool = require "connection_pool"

    -- Get a MongoDB connection from the pool
    local client, err = mongo_pool.get_connection()
    if not client then
        ngx.log(ngx.ERR, "Failed to get MongoDB connection: ", err)
        return
    end

    -- Select the database and collections
    local db = client:new_db_handle("Sera")
    local sera_hosts = db:get_col("sera_hosts")
    local oas_inventory = db:get_col("oas_inventory")

    -- Create change streams for both collections
    local sera_hosts_stream = sera_hosts:watch()
    local oas_inventory_stream = oas_inventory:watch()

    -- Listen for changes in sera_hosts collection
    local function listen_sera_hosts()
        for change in sera_hosts_stream do
            update_cache(change)
        end
    end

    -- Listen for changes in oas_inventory collection
    local function listen_oas_inventory()
        for change in oas_inventory_stream do
            update_cache(change)
        end
    end

    -- Start listening in separate coroutines
    ngx.thread.spawn(listen_sera_hosts)
    ngx.thread.spawn(listen_oas_inventory)
end

return {
    listen_to_changes = listen_to_changes
}
