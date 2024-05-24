local mongo_handler = require("mongo_handler")
local cjson = require("cjson")
local ngx_cache = ngx.shared.oas_cache

local function update_oas_cache()
    -- Retrieve all entries from the sera_hosts collection
    local sera_hosts_json, err = mongo_handler.get_settings("sera_hosts", {})
    if not sera_hosts_json then
        ngx.log(ngx.ERR, "Failed to retrieve sera_hosts: ", err)
        return ngx.exit(500)
    end

    local sera_hosts = cjson.decode(sera_hosts_json)
    if not sera_hosts then
        ngx.log(ngx.ERR, "Failed to decode sera_hosts JSON: ", err)
        return ngx.exit(500)
    end

    -- Iterate over all sera_hosts entries
    for _, host_entry in ipairs(sera_hosts) do
        local hostname = host_entry.hostname
        local oas_spec_id = host_entry.oas_spec

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
    end
end

return {
    update_oas_cache = update_oas_cache
}
