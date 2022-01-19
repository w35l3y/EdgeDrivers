-- https://community.smartthings.com/t/st-edge-change-driver-tool-in-the-st-app/230956/23?u=w35l3y
--[[
    New installation of a device:
    EDGE: init → added → doConfigure → infoChanged
    DTH: installed → configure → parse

    Uninstalling the device:
    EDGE: removed (in documentation says “deleted”)

    Change of EDGE driver for another one for a device in app:
    EDGE: init → added → driverSwitched → infoChanged
    DTH change in IDE: configure → parse
--]]

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

--[[
ERROS QUE OCORREM APÓS INCLUIR CHILD DEVICES

AUTOMATICO
[string "lifecycles"]:47: attempt to call a nil value (method 'set_component_to_endpoint_fn')
[string "st.zigbee.device_management"]:207: attempt to call a nil value (method 'configure')
[string "st.zigbee.device_management"]:136: attempt to call a nil value (method 'check_monitored_attributes')

MANUAL AO CLICAR NO BOTÃO
[string "st.zigbee.cluster_base"]:294: attempt to call a nil value (method 'get_short_address')

--]]
function lifecycle_handler.init(driver, device, event, args)
  log.info("device_init")

  commands.update_endpoints(driver, device)
--  log.info("event=" .. event)
--  log.info(utils.stringify_table(args, "args", true))

  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)

--  device:set_field("zigbee_endpoints")
--  log.info(utils.stringify_table(device, "device", true))

  device:set_field("onOff", "catchall")  -- updateDataValue("onOff", "catchall")
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

-- https://developer-preview.smartthings.com/edge-device-drivers/zigbee/driver.html#example

--function lifecycle_handler.fallback(driver, device, event, args)
--  log.trace(string.format("received unhandled lifecycle event: %s", event))
--end

--function lifecycle_handler.error(driver, device, event, args)
--  log.error(string.format("Error encountered while processing event for %s", tostring(device)))
--end

return lifecycle_handler
