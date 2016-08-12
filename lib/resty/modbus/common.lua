local lib = require "resty.modbus"
local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_cdef = ffi.cdef
local ffi_errno = ffi.errno
local ffi_typeof = ffi.typeof
local ffi_sizeof = ffi.sizeof
local ffi_copy = ffi.copy

ffi_cdef[[
extern const unsigned int libmodbus_version_major;
extern const unsigned int libmodbus_version_minor;
extern const unsigned int libmodbus_version_micro;
typedef struct _modbus modbus_t;
int modbus_connect(modbus_t *ctx);
void modbus_free(modbus_t *ctx);
void modbus_close(modbus_t *ctx);
int modbus_flush(modbus_t *ctx);
const char *modbus_strerror(int errnum);
int modbus_set_debug(modbus_t *ctx, int flag);
int modbus_set_slave(modbus_t* ctx, int slave);
int modbus_send_raw_request(modbus_t *ctx, uint8_t *raw_req, int raw_req_length);
int modbus_get_response_timeout(modbus_t *ctx, uint32_t *to_sec, uint32_t *to_usec);
int modbus_set_response_timeout(modbus_t *ctx, uint32_t to_sec, uint32_t to_usec);
int modbus_get_byte_timeout(modbus_t *ctx, uint32_t *to_sec, uint32_t *to_usec);
int modbus_set_byte_timeout(modbus_t *ctx, uint32_t to_sec, uint32_t to_usec);
int modbus_get_header_length(modbus_t *ctx);
int modbus_read_bits(modbus_t *ctx, int addr, int nb, uint8_t *dest);
int modbus_read_input_bits(modbus_t *ctx, int addr, int nb, uint8_t *dest);
int modbus_read_registers(modbus_t *ctx, int addr, int nb, uint16_t *dest);
int modbus_read_input_registers(modbus_t *ctx, int addr, int nb, uint16_t *dest);
int modbus_receive_confirmation(modbus_t *ctx, uint8_t *rsp);
int modbus_report_slave_id(modbus_t *ctx, int max_dest, uint8_t *dest);
int modbus_write_bit(modbus_t *ctx, int coil_addr, int status);
int modbus_write_register(modbus_t *ctx, int reg_addr, int value);
int modbus_write_bits(modbus_t *ctx, int addr, int nb, const uint8_t *data);
/*
int modbus_write_registers(modbus_t *ctx, int addr, int nb, const uint16_t *data);
int modbus_mask_write_register(modbus_t *ctx, int addr, uint16_t and_mask, uint16_t or_mask);
int modbus_write_and_read_registers(modbus_t *ctx, int write_addr, int write_nb, const uint16_t *src, int read_addr, int read_nb, uint16_t *dest);
void modbus_set_bits_from_byte(uint8_t *dest, int idx, const uint8_t value);
void modbus_set_bits_from_bytes(uint8_t *dest, int idx, unsigned int nb_bits, const uint8_t *tab_byte);
uint8_t modbus_get_byte_from_bits(const uint8_t *src, int idx, unsigned int nb_bits);
float modbus_get_float(const uint16_t *src);
float modbus_get_float_abcd(const uint16_t *src);
float modbus_get_float_dcba(const uint16_t *src);
float modbus_get_float_badc(const uint16_t *src);
float modbus_get_float_cdab(const uint16_t *src);
void modbus_set_float(float f, uint16_t *dest);
void modbus_set_float_abcd(float f, uint16_t *dest);
void modbus_set_float_dcba(float f, uint16_t *dest);
void modbus_set_float_badc(float f, uint16_t *dest);
void modbus_set_float_cdab(float f, uint16_t *dest);
*/
]]

local size8t  = ffi_sizeof "uint8_t"
local size16t = ffi_sizeof "uint16_t"

local dest8t = ffi_typeof "uint8_t[?]"
local dest16t = ffi_typeof "uint16_t[?]"

local time32t = ffi_typeof "uint32_t[1]"

local sec = ffi_new(time32t)
local usec = ffi_new(time32t)

local rsp = ffi_new(dest8t, 260)

local function strerror(errno)
    return ffi_str(lib.modbus_strerror(errno or ffi_errno()))
end

local common = { strerror = strerror, version = lib.libmodbus_version_major .. "." .. lib.libmodbus_version_minor .. "." .. lib.libmodbus_version_micro }

function common:connect()
    local rt = lib.modbus_connect(self.context)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:close()
    lib.modbus_close(self.context)
end

function common:flush()
    local rt = lib.modbus_close(self.context)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:set_debug(enable)
    local rt = lib.modbus_set_debug(self.context, not not enable)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:set_slave(slave)
    local rt = lib.modbus_set_slave(self.context, slave)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:send_raw_request(raw)
    local len = #raw
    local req = ffi_new(dest8t, len)
    ffi_copy(req, raw, len)
    len = lib.modbus_send_raw_request(self.context, req, len)
    if len == -1 then
        return nil, strerror()
    end
    return len
end

function common:receive_confirmation(len)
    local rsp = len and ffi_new(dest8t, len) or rsp
    local len = lib.modbus_receive_confirmation(self.context, rsp)
    if len == -1 then
        return nil, strerror()
    end
    if len == 0 then
        return "", 0
    end
    return ffi_str(rsp, len)
end

function common:get_byte_timeout()
    local rt = lib.modbus_get_byte_timeout(self.context, sec, usec)
    if rt == -1 then
        return nil, strerror()
    end
    return sec[0], usec[0]
end

function common:set_byte_timeout(sec, usec)
    local rt = lib.modbus_set_byte_timeout(self.context, sec, usec)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:get_response_timeout()
    local rt = lib.modbus_get_response_timeout(self.context, sec, usec)
    if rt == -1 then
        return nil, strerror()
    end
    return sec[0], usec[0]
end

function common:set_response_timeout(sec, usec)
    local rt = lib.modbus_set_response_timeout(self.context, sec, usec)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:get_header_length()
    return lib.modbus_get_header_length(self.context)
end

function common:read_bits(addr, nb)
    nb = nb or 1
    local dest = ffi_new(dest8t, nb * size8t)
    local bits = lib.modbus_read_bits(self.context, addr, nb, dest)
    if bits == -1 then
        return nil, strerror()
    end
    return ffi_str(dest, bits)
end

function common:read_input_bits(addr, nb)
    nb = nb or 1
    local dest = ffi_new(dest8t, nb * size8t)
    local bits = lib.modbus_read_input_bits(self.context, addr, nb, dest)
    if bits == -1 then
        return nil, self.strerror()
    end
    return ffi_str(dest, bits)
end

function common:read_registers(addr, nb)
    nb = nb or 1
    local dest = ffi_new(dest16t, nb * size16t)
    local regs = lib.modbus_read_registers(self.context, addr, nb, dest)
    if regs == -1 then
        return nil, strerror()
    end
    regs = regs - 1
    local res = {}
    for i=0, regs do
        res[i+1] = dest[i]
    end
    return res
end

function common:read_input_registers(addr, nb)
    nb = nb or 1
    local dest = ffi_new(dest16t, nb * size16t)
    local regs = lib.modbus_read_input_registers(self.context, addr, nb, dest)
    if regs == -1 then
        return nil, strerror()
    end
    regs = regs - 1
    local res = {}
    for i=0, regs do
        res[i+1] = dest[i]
    end
    return res
end

function common:report_slave_id(max_dest)
    local rsp = max_dest and ffi_new(dest8t, max_dest) or rsp
    local rt = lib.modbus_report_slave_id(self.context, max_dest or 260, rsp)
    if rt == -1 then
        return nil, strerror()
    end
    return ffi_str(rsp, rt)
end

function common:write_bit(coil_addr, status)
    local rt = lib.modbus_write_bit(self.context, coil_addr, not not status)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:write_register(reg_addr, value)
    local rt = lib.modbus_write_register(self.context, reg_addr, value)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

function common:write_bits(addr, nb, data)
    local rt = lib.modbus_write_bits(self.context, addr, nb, data)
    if rt == -1 then
        return nil, strerror()
    end
    return rt
end

return common