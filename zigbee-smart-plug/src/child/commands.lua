local json = require("dkjson")
local parent_commands = require("commands")

local function component_to_endpoint(device)
  return tonumber(device.device_network_id:sub(6), 16)  -- XXXX:EP
end

local function corrected_eps(zigbee_endpoints)
  local output = {}
  for key, ep in pairs(zigbee_endpoints) do
    output[tonumber(key)] = ep
  end
  return output
end

function do_nothing() end
  
local commands = {}

function commands.mimic_zigbee_device(driver, device)
  local device_cloud = json.decode(driver.device_api.get_device_info(device.id))
  device_cloud.fingerprinted_endpoint_id = component_to_endpoint(device)
  device_cloud.zigbee_endpoints = {
    [tostring(device_cloud.fingerprinted_endpoint_id)] = {
      id = device_cloud.fingerprinted_endpoint_id,
      client_clusters = {},
      manufacturer = device_cloud.manufacturer,
      model = device_cloud.model,
      device_id = 0x010A,  -- deviceIdentifiers
      profile_id = 0x0104,  -- zigbeeProfiles
      server_clusters = { 0x0003, 0x0004, 0x0005, 0x0006, 0xE000, 0xE001 }
    }
  }
  device:load_updated_data(device_cloud)

  -- ATTRIBUTES
  rawset(device, "fingerprinted_endpoint_id", device_cloud.fingerprinted_endpoint_id)

  rawset(device, "zigbee_endpoints", corrected_eps(device_cloud.zigbee_endpoints))

  rawset(device, "zigbee_channel", driver.zigbee_channel)
  -- /ATTRIBUTES

  -- FUNCTIONS
  rawset(device, "get_endpoint_for_component_id", component_to_endpoint)
  
  rawset(device, "check_monitored_attributes", do_nothing)

  rawset(device, "configure", do_nothing)

  rawset(device, "emit_event_for_endpoint", function(_self, endpoint, event)
    _self:emit_component_event(_self.profile.components.main, event)
  end)

  rawset(device, "get_short_address", function (_self)
    return tonumber(device.device_network_id:sub(1, 4), 16)
  end)

  rawset(device, "get_endpoint", function (_self, cluster)
    return component_to_endpoint(_self)
  end)

  rawset(device, "send_to_component", function (_self, component_id, zb_tx)
    _self.zigbee_channel:send(_self.id, zb_tx:to_component(_self, component_id))
  end)
  -- /FUNCTIONS
end

function commands.get_parent_device (driver, device)
  local dsaddr = device:get_short_address()
  for _, parentDevice in ipairs(driver:get_devices()) do
    if parent_commands.is_same_device(parentDevice, dsaddr, 1) then
      return parentDevice
    end
  end
  error("Parent device not found")
  return nil
end


return commands