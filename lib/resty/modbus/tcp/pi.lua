local lib = require "resty.modbus"
local common = require "resty.modbus.common"
local strerror = common.strerror
local ffi = require "ffi"
local ffi_gc = ffi.gc
local ffi_cdef = ffi.cdef
local setmetatable = setmetatable
local pairs = pairs

ffi_cdef[[
modbus_t* modbus_new_tcp_pi(const char *node, const char *service);
int modbus_tcp_pi_listen(modbus_t *ctx, int nb_connection);
int modbus_tcp_pi_accept(modbus_t *ctx, int *s);
]]

local pi = {}
pi.__index = pi
function pi.new(node, service)
    local context = ffi_gc(lib.modbus_new_tcp_pi(node, service or "502"), lib.modbus_free)
    if context == nil then
        return nil, strerror()
    end
    return setmetatable({ context = context }, pi)
end
function pi:listen(nb_connection)
    local socket = lib.modbus_tcp_pi_listen(self.context, nb_connection)
    if socket == -1 then
        return nil, strerror()
    end
    return socket
end
function pi:accept(socket)
    local s = lib.modbus_tcp_pi_accept(self.context, socket)
    if s == -1 then
        return nil, strerror()
    end
    return s
end

for k, v in pairs(common) do
    pi[k] = v
end

return pi
