local log = require("log")
local utils = require("st.utils")
local capabilities = require("st.capabilities")
local device_management = require("st.zigbee.device_management")
local switch_defaults = require("st.zigbee.defaults.switch_defaults")
local commands = require("child.commands")

local overridden_defaults = {}

function overridden_defaults.on_off_attr_handler(driver, device, value, zb_rx)
  log.info("[CHILD] overridden_defaults.on_off_attr_handler")
  log.info(utils.stringify_table(value, "value", true))
  log.info(zb_rx:pretty_print())

  switch_defaults.on_off_attr_handler(driver, device, value, zb_rx)
end

function overridden_defaults.default_response_handler(driver, device, zb_rx)
  log.info("[CHILD] overridden_defaults.default_response_handler")

  switch_defaults.default_response_handler(driver, device, zb_rx)
end

function overridden_defaults.on(driver, device, command)
  log.info("[CHILD] overridden_defaults.on")

  local status, parentDevice = pcall(commands.get_parent_device, driver, device)
  if status then
    switch_defaults.on(driver, parentDevice, utils.merge({
      component = "main_" .. device:get_endpoint_for_component_id("main")
    }, command))
  else
    log.warn(string.format("Error: %s", tostring(parentDevice)))
  end
end

function overridden_defaults.off(driver, device, command)
  log.info("[CHILD] overridden_defaults.off")

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