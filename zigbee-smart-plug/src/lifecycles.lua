-- https://community.smartthings.com/t/st-edge-change-driver-tool-in-the-st-app/230956/23?u=w35l3y

local log = require('log')
local utils = require('st.utils')
local capabilities = require('st.capabilities')
local commands = require('commands')
local device_management = require("st.zigbee.device_management")

local function component_to_endpoint(device, component_id)
  if component_id == "main" then
    return device.fingerprinted_endpoint_id
  else
    local ep_num = component_id:match("main_(%d)")
    return ep_num and tonumber(ep_num) or device.fingerprinted_endpoint_id
  end
end

local function endpoint_to_component(device, ep)
  if ep == device.fingerprinted_endpoint_id then
    return "main"
  else
    return string.format("main_%d", ep)
  end
end

-- https://github.com/SmartThingsDevelopers/SampleDrivers/blob/main/lightbulb-lan-esp8266/driver/src/lifecycles.lua
local lifecycle_handler = {}

function lifecycle_handler.doConfigure(driver, device, event, args)
  log.info("doConfigure")
  log.info("event = " .. event)
  log.info(utils.stringify_table(args, "args", true))

  device_management.configure(driver, device, event, args)
end

function lifecycle_handler.init(driver, device, event, args)
  log.info("device_init")

  commands.update_endpoints(driver, device)

  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)

  device:set_field("onOff", "catchall")
end

-- executado antes do "init"
function lifecycle_handler.added(driver, device, event, args)
  log.info("device_added")

  commands.createChildDevices(driver, device)
end

function lifecycle_handler.infoChanged(driver, device, event, args)
  log.info("device_infoChanged")

  -- @TODO Verificar se será necessário ajustar device_network_id dos child, por exemplo
end

function lifecycle_handler.removed(driver, device, event, args)
  log.info("device_removed")

  -- @TODO Criar lógica de remover filhos
end

return lifecycle_handler
