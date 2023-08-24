local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"

local cluster_base = require "st.zigbee.cluster_base"
local read_attribute = require "st.zigbee.zcl.global_commands.read_attribute"
local zcl_messages = require "st.zigbee.zcl"
local messages = require "st.zigbee.messages"
local zb_const = require "st.zigbee.constants"

function cluster_base.read_attributes(device, cluster_id, attr_ids)
  local read_body = read_attribute.ReadAttribute(attr_ids)
  local zclh = zcl_messages.ZclHeader({
    cmd = data_types.ZCLCommandId(read_attribute.ReadAttribute.ID)
  })
  local addrh = messages.AddressHeader(
      zb_const.HUB.ADDR,
      zb_const.HUB.ENDPOINT,
      device:get_short_address(),
      device:get_endpoint(cluster_id.value),
      zb_const.HA_PROFILE_ID,
      cluster_id.value
  )
  local message_body = zcl_messages.ZclMessageBody({
    zcl_header = zclh,
    zcl_body = read_body
  })
  return messages.ZigbeeMessageTx({
    address_header = addrh,
    body = message_body
  })
end

local profiles = {
  carbonmonoxide_v1 = {
    zcl_clusters.CarbonMonoxide,
  },
  colordimmer_v1 = {
    zcl_clusters.OnOff,
    zcl_clusters.Level,
    zcl_clusters.ColorControl,
  },
  dimmer_v1 = {
    zcl_clusters.OnOff,
    zcl_clusters.Level,
  },
  humidity_v1 = {
    zcl_clusters.RelativeHumidity,
  },
  lock_v1 = {
    zcl_clusters.DoorLock,
  },
  occupancy_v1 = {
    zcl_clusters.OccupancySensing,
  },
  power_v1 = {
    zcl_clusters.SimpleMetering,
    zcl_clusters.ElectricalMeasurement,
  },
  switch_v1 = {
    zcl_clusters.OnOff,
  },
  temperature_v1 = {
    zcl_clusters.TemperatureMeasurement,
  },
  temphumi_v1 = {
    zcl_clusters.RelativeHumidity,
    zcl_clusters.TemperatureMeasurement,
  },
  temphumibatt_v1 = {
    zcl_clusters.PowerConfiguration,
    zcl_clusters.RelativeHumidity,
    zcl_clusters.TemperatureMeasurement,
  },
  thermostat_v1 = {
    zcl_clusters.TemperatureMeasurement,
    zcl_clusters.RelativeHumidity,
    zcl_clusters.Thermostat,
  },
  -- valve_v1 = {
  --   zcl_clusters.OnOff,
  -- },
  windowshade_v1 = {
    zcl_clusters.WindowCovering,
  },
}

local utils = {}

function utils.spell_magic_trick (device)
  device:send(cluster_base.read_attributes(device, data_types.ClusterId(zcl_clusters.Basic.ID), {
    data_types.AttributeId(zcl_clusters.Basic.attributes.ManufacturerName.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.ZCLVersion.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.ApplicationVersion.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.ModelIdentifier.ID),
    data_types.AttributeId(zcl_clusters.Basic.attributes.PowerSource.ID),
    data_types.AttributeId(0xFFFE),
  }))
end

function utils.get_profiles (device, ep_id)
  local result = {}
  local exists = false
  for name, clusters in pairs(profiles) do
    local count = 0
    local found = 0
    for _,cluster in ipairs(clusters) do
      if device:supports_server_cluster(cluster.ID, ep_id) then
        found = found + 1
        exists = true
      end
      count = count + 1
    end
    result[#result+1] = {
      name = name,
      found = found,
      count = count,
    }
  end
  if exists then
    table.sort(result, function (a, b)
      if a.found > b.found then return true end
      if a.found == b.found then
        return a.count < b.count
      end
      return false
    end)
  end
  return exists, result
end

function utils.update_profile (device, profile)
  device:try_update_metadata({
    profile = profile
  })
end

function utils.find_child_fn (device, group)
  return device:get_child_by_parent_assigned_key(string.format("%02X", group))
end

function utils.create_child (driver, device, ngroup, profile)
  local group = string.format("%02X", ngroup)
  local created = device:get_child_by_parent_assigned_key(group)
  if not created then
    driver:try_create_device({
      type = "EDGE_CHILD",
      device_network_id = nil,
      parent_assigned_child_key = group,
      label = "Child " .. ngroup,
      profile = profile,
      parent_device_id = device.id,
      manufacturer = driver.NAME,
      model = profile,
      vendor_provided_label = "Child " .. ngroup,
    })
  end
end

local function hexa(value, length)
  return string.format("0x%0"..(length or 4).."X", value or 0)
end

local function map(endpoints, key)
  local o = {}
  for dpid, clusters in pairs(endpoints) do
    for index, cluster in ipairs(clusters[key]) do
      if not o[cluster] then
        o[cluster] = {
          name = zcl_clusters.id_to_name_map[cluster] or "?",
          endpoints = {}
        }
      end
      local x = o[cluster]
      x.endpoints[#x.endpoints+1] = hexa(dpid, 2)
    end
  end
  setmetatable(o, {
    __tostring = function (self)
      local output = {}
      for cluster,info in pairs(self) do
        output[#output+1] = string.format('<tr><th align="left">%s</th><td>0x%04X</td><td>%s</td></tr>', info.name, cluster, table.concat(info.endpoints, ", "))
      end
      if #output==0 then
        output[#output+1] = '<tr><td colspan="3">None</td></tr>'
      end
      return table.concat(output)
    end
  })

  return o
end

function utils.info(device)
  local fei = device.zigbee_endpoints[device.fingerprinted_endpoint_id] or device.zigbee_endpoints[tostring(device.fingerprinted_endpoint_id)] or {}

  local o = {
    manufacturer = device:get_manufacturer(),
    model = device:get_model(),
    endpoint = hexa(device.fingerprinted_endpoint_id, 2),
    device_id = hexa(fei.device_id, 4),
    profile_id = hexa(fei.profile_id, 4),
    network_id = "0x" .. device.device_network_id,
    server = map(device.zigbee_endpoints, "server_clusters"),
    client = map(device.zigbee_endpoints, "client_clusters"),
  }
  setmetatable(o, {__tostring = function (self)
    return string.format(
      [[<table style="font-size:0.6em;min-width:100%%"><tbody>
        <tr><th align="left" style="width:40%%">Manufacturer</th><td colspan="2" style="width:60%%">%s</td></tr>
        <tr><th align="left">Model</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Endpoint</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Device ID</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Network ID</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Profile ID</th><td colspan="2">%s</td></tr>
        <tr><th colspan="3">Server Clusters</th></tr>
        %s
        <tr><th colspan="3">Client Clusters</th></tr>
        %s
      </tbody></table>]],
      self.manufacturer,
      self.model,
      self.endpoint,
      self.device_id,
      self.network_id,
      self.profile_id,
      self.server,
      self.client
    )
  end})

  return o
end

local started_at = os.time()

function utils.details(driver)
  driver:call_on_schedule(60, function()
    local diff = os.difftime(os.time(), started_at)
    -- collectgarbage("collect")
    local memory = math.ceil(collectgarbage("count"))
    print(string.format("start: %s, uptime: %02d:%02d:%02d, memory: %d KB, devices: %d", os.date("%Y-%m-%d %H:%M:%S", started_at), math.floor(diff/3600), math.floor((diff%3600)/60), diff % 60, memory, #driver:get_devices()))
  end)
end

local carbonMonoxideDetector_defaults = require "st.zigbee.defaults.carbonMonoxideDetector_defaults"
local contactSensor_defaults = require "st.zigbee.defaults.contactSensor_defaults"
local motionSensor_defaults = require "st.zigbee.defaults.motionSensor_defaults"
local smokeDetector_defaults = require "st.zigbee.defaults.smokeDetector_defaults"
local soundSensor_defaults = require "st.zigbee.defaults.soundSensor_defaults"
local waterSensor_defaults = require "st.zigbee.defaults.waterSensor_defaults"

function utils.ias_zone_status_change_handler(...)
  pcall(carbonMonoxideDetector_defaults.ias_zone_status_change_handler, ...)
  pcall(contactSensor_defaults.ias_zone_status_change_handler, ...)
  pcall(motionSensor_defaults.ias_zone_status_change_handler, ...)
  pcall(smokeDetector_defaults.ias_zone_status_change_handler, ...)
  pcall(soundSensor_defaults.ias_zone_status_change_handler, ...)
  pcall(waterSensor_defaults.ias_zone_status_change_handler, ...)
end

function utils.ias_zone_status_attr_handler(...)
  pcall(carbonMonoxideDetector_defaults.ias_zone_status_attr_handler, ...)
  pcall(contactSensor_defaults.ias_zone_status_attr_handler, ...)
  pcall(motionSensor_defaults.ias_zone_status_attr_handler, ...)
  pcall(smokeDetector_defaults.ias_zone_status_attr_handler, ...)
  pcall(soundSensor_defaults.ias_zone_status_attr_handler, ...)
  pcall(waterSensor_defaults.ias_zone_status_attr_handler, ...)
end

return utils