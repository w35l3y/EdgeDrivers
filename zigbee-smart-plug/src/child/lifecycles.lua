local log = require('log')
local utils = require('st.utils')
local commands = require("child.commands")

local lifecycle_handler = {}

function lifecycle_handler.doConfigure(driver, device, event, args)
  log.info("[CHILD] doConfigure " .. device.device_network_id)

  commands.mimic_zigbee_device(driver, device)
end

function lifecycle_handler.init(driver, device, event, args)
  log.info("[CHILD] device_init " .. device.device_network_id)

  -- device:online()

  commands.mimic_zigbee_device(driver, device)
end


function lifecycle_handler.added(driver, device, event, args)
  log.info("[CHILD] device_added " .. device.device_network_id)

  commands.mimic_zigbee_device(driver, device)
end

function lifecycle_handler.infoChanged(driver, device, event, args)
  log.info("[CHILD] device_infoChanged " .. device.device_network_id)
  
  commands.mimic_zigbee_device(driver, device)
end

return lifecycle_handler
