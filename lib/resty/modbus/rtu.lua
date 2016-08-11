local lib = require "resty.modbus"
local common = require "resty.modbus.common"
local strerror = common.strerror
local enums = require "resty.modbus.enums"
local parities = enums.parity
local sermodes = enums.serial.modes
local rts = enums.rts
local type = type
local ffi = require "ffi"
local ffi_gc = ffi.gc
local ffi_cdef = ffi.cdef
local setmetatable = setmetatable
local pairs = pairs

ffi_cdef[[
modbus_t* modbus_new_rtu(const char *device, int baud, char parity, int data_bit, int stop_bit);
int modbus_rtu_set_serial_mode(modbus_t *ctx, int mode);
int modbus_rtu_get_serial_mode(modbus_t *ctx);
int modbus_rtu_set_rts(modbus_t *ctx, int mode);
int modbus_rtu_get_rts(modbus_t *ctx);
//int modbus_rtu_set_custom_rts(modbus_t *ctx, void (*set_rts) (modbus_t *ctx, int on));
int modbus_rtu_set_rts_delay(modbus_t *ctx, int us);
int modbus_rtu_get_rts_delay(modbus_t *ctx);
]]

local rtu = {}
rtu.__index = rtu
function rtu.new(device, baud, parity, data_bit, stop_bit)
    local context = ffi_gc(lib.modbus_new_rtu(device, baud or 115200, parity or parities.none, data_bit or 8, stop_bit or 1), lib.modbus_free)
    if context == nil then
        return nil, strerror()
    end
    return setmetatable({ context = context }, rtu)
end
function rtu:set_serial_mode(mode)
    if type(mode) ~= "number" then
        mode = sermodes[mode] or sermodes.rs232
    end
    local rt = lib.modbus_rtu_set_serial_mode(self.context, mode)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end
function rtu:get_serial_mode()
    local mode = lib.modbus_rtu_get_serial_mode(self.context)
    if mode == -1 then
        return nil, strerror()
    end
    return mode
end
function rtu:set_rts(mode)
    if type(mode) ~= "number" then
        mode = rts[mode] or rts.none
    end
    local rt = lib.modbus_rtu_set_rts(self.context, mode)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end
function rtu:get_rts()
    local mode = lib.modbus_rtu_get_rts(self.context)
    if mode == -1 then
        return nil, strerror()
    end
    return mode
end
function rtu:set_rts_delay(usec)
    local rt = lib.modbus_rtu_set_rts_delay(self.context, usec)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end
function rtu:get_rts_delay()
    local delay = lib.modbus_rtu_get_rts_delay(self.context)
    if delay == -1 then
        return nil, strerror()
    end
    return delay
end

for k, v in pairs(common) do
    rtu[k] = v
end

return rtu
