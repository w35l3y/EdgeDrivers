local log = require('log')
local utils = require('st.utils')
local json = require('dkjson')

local function getChildCount (driver, device)
  return 5
end

local function getEndpoint (device, index)
  if index == 5 and device.model == "TS0115" then
    return "07"
  end
  return string.format("%02X", index)
end

local commands = {}

function commands.update_endpoints(driver, device)
  local device_cloud = json.decode(driver.device_api.get_device_info(device.id))
  
  device_cloud.model = nil
  for _, ep in pairs(device_cloud.zigbee_endpoints) do
    if ep.model ~= nil then
      device_cloud.model = ep.model
      break
    end
  end

  local output = {}
  for index=5, getChildCount(driver, device_cloud) do
    local e = tonumber(getEndpoint(device_cloud, index), 16)
    output[tostring(e)] = utils.merge({
      id = e
    }, device_cloud.zigbee_endpoints["2"])
  end

  device_cloud.zigbee_endpoints = utils.merge(output, device_cloud.zigbee_endpoints)
  device:load_updated_data(device_cloud)
end

function commands.refresh (driver, device)
  device:refresh()
end

function commands.createChildDevices (driver, device)
  if not device:get_field("child-created") then
    device:set_field("child-created", true)

    local metadata = {
      type = "LAN",
      profile = "child-smart-plug.v1",
      manufacturer = device:get_manufacturer(),
      model = device:get_model(),
      -- parent_device_id = device.id, -- não cria os child devices quando acrescento esta linha
      vendor_provided_label = "Child Smart Plug"
    }
    -- https://developer-preview.smartthings.com/edge-device-drivers/driver.html#Driver.try_create_device
    for index=2,getChildCount(driver, metadata) do
      local merged_metadata = utils.merge({
        device_network_id = device.device_network_id .. ':' .. getEndpoint(metadata, index),
        label = "Child Smart Plug " .. index
      }, metadata)
      local newDevice, err, err_msg = driver:try_create_device(merged_metadata)
      if err then
        log.error(err_msg)
      end
    end
  end
  commands.refresh(driver, device)
end

function commands.is_same_device(device, dsaddr, endpoint_id)
  if device.device_network_id ~= nil then
    return dsaddr == tonumber(device.device_network_id:sub(1, 4), 16) and ((not device.device_network_id:match(":") and endpoint_id == 1) or endpoint_id == tonumber(device.device_network_id:sub(6), 16))
  else
    return dsaddr == device:get_short_address() and endpoint_id == tonumber(device:get_endpoint_for_component_id("main"))
  end
end

return commands
