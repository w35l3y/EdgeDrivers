local log = require("log")
local utils = require("st.utils")
local capabilities = require("st.capabilities")
local device_management = require("st.zigbee.device_management")
local switch_defaults = require("st.zigbee.defaults.switch_defaults")
local commands = require("child.commands")

local overridden_defaults = {}

--[[
AUTOMÁTICO

value={
  field_name="OnOff", 
  value=false, 
}
< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xC720, src_endpoint: 0x01, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0x6C, rssi: -73, body_length: 0x0007, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x18, seqno: 0x6E, ZCLCommandId: 0x0A >, < ReportAttribute || < AttributeRecord || AttributeId: 0x0000, DataType: Boolean, OnOff: false > > > >
--]]
function overridden_defaults.on_off_attr_handler(driver, device, value, zb_rx)
  log.info("[CHILD] overridden_defaults.on_off_attr_handler")
  log.info(utils.stringify_table(value, "value", true))
  log.info(zb_rx:pretty_print())

  switch_defaults.on_off_attr_handler(driver, device, value, zb_rx)
end

--[[
MANUAL

< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xC720, src_endpoint: 0x05, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0x70, rssi: -72, body_length: 0x0005, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x6F, ZCLCommandId: 0x0B >, < DefaultResponse || cmd: 0x01, ZclStatus: SUCCESS > > >

< ZigbeeMessageRx || type: 0x00, < AddressHeader || src_addr: 0xC720, src_endpoint: 0x05, dest_addr: 0x0000, dest_endpoint: 0x01, profile: 0x0104, cluster: OnOff >, lqi: 0x68, rssi: -74, body_length: 0x0005, < ZCLMessageBody || < ZCLHeader || frame_ctrl: 0x08, seqno: 0x77, ZCLCommandId: 0x0B >, < DefaultResponse || cmd: 0x00, ZclStatus: SUCCESS > > >
--]]
function overridden_defaults.default_response_handler(driver, device, zb_rx)
  log.info("[CHILD] overridden_defaults.default_response_handler")
--  log.info(zb_rx:pretty_print())

  switch_defaults.default_response_handler(driver, device, zb_rx)
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
  log.info("[CHILD] overridden_defaults.on")
--  log.info("endpoint=" .. device:get_endpoint_for_component_id("main"))
--  command.component = "main_" .. device:get_endpoint_for_component_id("main")
--  log.info(utils.stringify_table(command, "command_on", true))

--  não dá pra mandar esse comando pq ele atualiza o status do "main" do device original
--  switch_defaults.on(driver, device, command)

  local status, parentDevice = pcall(commands.get_parent_device, driver, device)
  if status then
    switch_defaults.on(driver, parentDevice, utils.merge({
      component = "main_" .. device:get_endpoint_for_component_id("main")
    }, command))
  else
    log.warn(string.format("Error: %s", tostring(parentDevice)))
  end
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
  log.info("[CHILD] overridden_defaults.off")
--  log.info("endpoint=" .. device:get_endpoint_for_component_id("main"))
--  command.component = "main_" .. device:get_endpoint_for_component_id("main")
--  log.info(utils.stringify_table(command, "command_off", true))

--  não dá pra mandar esse comando pq ele atualiza o status do "main" do device original
--  switch_defaults.off(driver, device, command)

  local status, parentDevice = pcall(commands.get_parent_device, driver, device)
  if status then
    switch_defaults.off(driver, parentDevice, utils.merge({
      component = "main_" .. device:get_endpoint_for_component_id("main")
    }, command))
  else
    log.warn(string.format("Error: %s", tostring(parentDevice)))
  end
end

function overridden_defaults.refresh(driver, device)
  log.info("[CHILD] overridden_defaults.refresh")
  device_management.refresh(driver, device)
end

function overridden_defaults.configure(driver, device, command)
  log.info("[CHILD] overridden_defaults.configure")
  log.info(utils.stringify_table(command, "config", true))
end


return overridden_defaults