local log = require('log')
local utils = require('st.utils')
local capabilities = require('st.capabilities')
local device_management = require("st.zigbee.device_management")
local switch_defaults = require("st.zigbee.defaults.switch_defaults")
local commands = require("commands")

local overridden_defaults = {}

function overridden_defaults.on_off_attr_handler(driver, device, value, zb_rx)
  log.info("overridden_defaults.on_off_attr_handler")

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
end

function overridden_defaults.default_response_handler(driver, device, zb_rx)
  log.info("overridden_defaults.default_response_handler")
end

function overridden_defaults.on(driver, device, command)
  log.info("overridden_defaults.on")
  log.info(utils.stringify_table(command, "command_on", true))

  switch_defaults.on(driver, device, command)
end

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