local log = require('log')
local utils = require('st.utils')
local capabilities = require('st.capabilities')
local device_management = require("st.zigbee.device_management")
local switch_defaults = require("st.zigbee.defaults.switch_defaults")
local commands = require("commands")

local overridden_defaults = {}

--[[
AUTOMATICO

value={
  field_name="OnOff", 
  value=false, 
}
< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xC720, src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0x6C, rssi: -73, body_length: 0x0007, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x18, seqno: 0x6E, ZCLCommandId: 0x0A >, < ReportAttribute || < AttributeRecord || AttributeId: 0x0000, DataType: Boolean, OnOff: false > > > >
--]]
function overridden_defaults.on_off_attr_handler(driver, device, value, zb_rx)
  log.info("overridden_defaults.on_off_attr_handler")
--  log.info(utils.stringify_table(value, "value", true))
--  log.info(zb_rx:pretty_print())

-- esta linha não pode ser removida pois atualiza o status do device real
  switch_defaults.on_off_attr_handler(driver, device, value, zb_rx)

-- o trecho abaixo atualiza o device virtual, caso ele ainda exista
  local src_endpoint = zb_rx.address_header.src_endpoint.value
  if src_endpoint ~= 1 then
    local attr = capabilities.switch.switch
    local dsaddr = device:get_short_address()
    for _, childDevice in ipairs(driver:get_devices()) do
      if commands.is_same_device(childDevice, dsaddr, src_endpoint) then
        childDevice:emit_component_event(childDevice.profile.components.main, value.value and attr.on() or attr.off())
        break
      end
    end
  end

  -- log.info(utils.stringify_table(device, "device", true))
end

--[[
MANUAL

< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xC720, src_endpoint: 0x05, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0x70, rssi: -72, body_length: 0x0005, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x6F, ZCLCommandId: 0x0B >, < DefaultResponse || cmd: 0x01, ZclStatus: SUCCESS > > >

< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xC720, src_endpoint: 0x05, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0x68, rssi: -74, body_length: 0x0005, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x77, ZCLCommandId: 0x0B >, < DefaultResponse || cmd: 0x00, ZclStatus: SUCCESS > > >
--]]
function overridden_defaults.default_response_handler(driver, device, zb_rx)
  log.info("overridden_defaults.default_response_handler")
--  log.info(zb_rx:pretty_print())

  -- switch_defaults.default_response_handler(driver, device, zb_rx)
  -- device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, event)

  -- pcall(signalStrength_handler, device, zb_rx) -- podia, mas só pra não poluir
end

--[[
MANUAL

command_on={
  args={}, 
  capability="switch", 
  command="on", 
  component="main_5", 
  positional_args={}, 
}

CHILD
command_on={
  args={}, 
  capability="switch", 
  command="on", 
  component="main", 
  positional_args={}, 
}

--]]
function overridden_defaults.on(driver, device, command)
  log.info("overridden_defaults.on")
  log.info(utils.stringify_table(command, "command_on", true))

  switch_defaults.on(driver, device, command)
end

--[[
MANUAL

command_off={
  args={}, 
  capability="switch", 
  command="off", 
  component="main_5", 
  positional_args={}, 
}
--]]
function overridden_defaults.off(driver, device, command)
  log.info("overridden_defaults.off")
  log.info(utils.stringify_table(command, "command_off", true))

  switch_defaults.off(driver, device, command)
end

function overridden_defaults.refresh(driver, device)
  log.info("overridden_defaults.refresh")
  device_management.refresh(driver, device)
end

function overridden_defaults.configure(driver, device, command)
  log.info("overridden_defaults.configure")
  log.info(utils.stringify_table(command, "config", true))
end

return overridden_defaults