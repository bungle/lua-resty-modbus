local print = print
local exit = os.exit
local rtu, err, ok = require "resty.modbus.rtu".new("/dev/ttyXRUSB0")

if not rtu then
    print(err)
    exit(-1)
end

rtu:set_debug(true)

print("Connecting", rtu:connect())

print("Getting serial mode", rtu:get_serial_mode())
print("Setting serial mode", rtu:set_serial_mode("rs232"))
print("Getting serial mode", rtu:get_serial_mode())

print("Getting RTS mode", rtu:get_rts())
print("Setting RTS mode", rtu:set_rts("none"))
print("Getting RTS mode", rtu:get_rts())

print("Getting RTS delay", rtu:get_rts_delay())
print("Setting RTS delay", rtu:set_rts_delay(86))
print("Getting RTS delay", rtu:get_rts_delay())

print("Getting byte timeout", rtu:get_byte_timeout())
print("Setting byte timeout", rtu:set_byte_timeout(0, 500000))
print("Getting byte timeout", rtu:get_byte_timeout())

print("Getting response timeout", rtu:get_response_timeout())
print("Setting response timeout", rtu:set_response_timeout(0, 500000))
print("Getting response timeout", rtu:get_response_timeout())

print("Getting header length", rtu:get_header_length())

print("Setting slave", rtu:set_slave(1))

ok, err = rtu:read_input_registers(0x3110, 1)

print("Reading input registers, temperature", ok and ok[1] or err)

ok, err = rtu:read_input_registers(0x311A, 1)

print("Reading input registers, SOC", ok and ok[1] or err)

rtu:close()