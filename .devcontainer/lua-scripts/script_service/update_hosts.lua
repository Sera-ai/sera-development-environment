local request_data = require "request_data"
local cjson = require "cjson.safe"

local function read_hosts_file()
    local file = io.open("/etc/hosts", "r")
    if not file then
        return nil, "Could not open /etc/hosts for reading"
    end

    local content = file:read("*all")
    file:close()
    return content
end

local function write_hosts_file(content)
    local file = io.open("/etc/hosts", "w")
    if not file then
        return nil, "Could not open /etc/hosts for writing"
    end

    file:write(content)
    file:close()
    return true
end

local function update_hosts(action, hostname, ip)
    local content, err = read_hosts_file()
    if not content then
        return nil, err
    end

    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    if action == "add" then
        table.insert(lines, ip .. " " .. hostname)
    elseif action == "remove" then
        for i, line in ipairs(lines) do
            if line:match("%s" .. hostname .. "%s") then
                table.remove(lines, i)
                break
            end
        end
    elseif action == "update" then
        for i, line in ipairs(lines) do
            if line:match("%s" .. hostname .. "%s") then
                lines[i] = ip .. " " .. hostname
                break
            end
        end
    else
        return nil, "Invalid action"
    end

    local new_content = table.concat(lines, "\n")
    local success, write_err = write_hosts_file(new_content)
    if not success then
        return nil, write_err
    end

    return true
end

local function handle_request()

    local method = ngx.var.request_method
    local body = cjson.decode(request_data.get_request_body(method))

    
    local action = body.action
    local hostname = body.hostname
    local ip = body.ip

    if not action or not hostname or not ip then
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say('{"error": "Missing action, hostname, or ip parameter"}')
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    local success, err = update_hosts(action, hostname, ip)
    if not success then
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say('{"error": "' .. err .. '"}')
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    ngx.say('{"status": "success"}')
end

handle_request()