local lib = require "resty.modbus"
local common = require "resty.modbus.common"
local strerror = common.strerror
local ffi = require "ffi"
local ffi_gc = ffi.gc
local ffi_cdef = ffi.cdef
local setmetatable = setmetatable
local pairs = pairs

ffi_cdef[[
modbus_t* modbus_new_tcp(const char *ip_address, int port);
int modbus_tcp_listen(modbus_t *ctx, int nb_connection);
int modbus_tcp_accept(modbus_t *ctx, int *s);
]]

local tcp = {}
tcp.__index = tcp
function tcp.new(ip_address, port)
    local context = ffi_gc(lib.modbus_new_tcp(ip_address, port or 502), lib.modbus_free)
    if context == nil then
        return nil, strerror()
    end
    return setmetatable({ context = context }, tcp)
end
function tcp:listen(nb_connection)
    local socket = lib.modbus_tcp_listen(self.context, nb_connection)
    if socket == -1 then
        return nil, strerror()
    end
    return socket
end
function tcp:accept(socket)
    local s = lib.modbus_tcp_accept(self.context, socket)
    if s == -1 then
        return nil, strerror()
    end
    return s
end

for k, v in pairs(common) do
    tcp[k] = v
end

return tcp
