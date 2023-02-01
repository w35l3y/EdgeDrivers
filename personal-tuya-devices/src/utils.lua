local log = require "log"
local st_utils = require "st.utils"

local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local commands = require "commands"
local json = require "st.json"

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

function utils.is_normal(device)
  local pref = device.preferences.profile
  return (pref == nil and device.parent_assigned_child_key ~= nil) or (pref ~= nil and pref:find("^normal_") ~= nil)
end

function utils.is_same_profile(device, profile)
  return device.preferences ~= nil and device.preferences.profile == profile
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
          name = zcl_clusters.id_to_name_map[cluster],
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
        output[#output+1] = string.format('<tr><th align="left">%s</th><td>0x%04X</td><td>%s</td></tr>', info.name or "?", cluster, table.concat(info.endpoints, ", "))
      end
      if #output==0 then
        output[#output+1] = '<tr><td colspan="3">None</td></tr>'
      end
      return table.concat(output)
    end
  })

  return o
end

function utils.info(device, datapoints)
  local fei = device.zigbee_endpoints[device.fingerprinted_endpoint_id] or device.zigbee_endpoints[tostring(device.fingerprinted_endpoint_id)] or {}
  local _datapoints = datapoints or {}
  setmetatable(_datapoints, {
    __tostring = function (self)
      if datapoints == nil then
        return ""
      end
      local output = {}
      for _index, zb_rx in st_utils.pairs_by_key(self) do
        local _data = zb_rx.body.zcl_body.data
        output[#output+1] = string.format('<tr><th align="left">%s</th><td>%d</td><td>%s</td></tr>', _data.type:name(), _data.dpid.value, _data.value.value)
      end
      if #output == 0 then
        output[#output+1] = '<tr><td colspan="3">None</td></tr>'
      end
      return '<tr><th colspan="3">Datapoints</th></tr>' .. table.concat(output)
    end
  })

  local o = {
    manufacturer = device:get_manufacturer(),
    model = device:get_model(),
    endpoint = hexa(device.fingerprinted_endpoint_id, 2),
    device_id = hexa(fei.device_id, 4),
    profile_id = hexa(fei.profile_id, 4),
    server = map(device.zigbee_endpoints, "server_clusters"),
    client = map(device.zigbee_endpoints, "client_clusters"),
    datapoints = _datapoints,
  }
  setmetatable(o, {__tostring = function (self)
    return string.format(
      [[<table style="font-size:0.6em;min-width:100%%"><tbody>
        <tr><th align="left" style="width:40%%">Manufacturer</th><td colspan="2" style="width:60%%">%s</td></tr>
        <tr><th align="left">Model</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Endpoint</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Device ID</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Profile ID</th><td colspan="2">%s</td></tr>
        <tr><th colspan="3">Server Clusters</th></tr>
        %s
        <tr><th colspan="3">Client Clusters</th></tr>
        %s
        %s
      </tbody></table>]],
      self.manufacturer,
      self.model,
      self.endpoint,
      self.device_id,
      self.profile_id,
      self.server,
      self.client,
      self.datapoints
    )
  end})

  return o
end

function utils.settings(device)
  local o = {}
  if device.preferences ~= nil then
    for name, value in st_utils.pairs_by_key(device.preferences) do
      local normalized_id = st_utils.snake_case(name)
      local match, _length, key = string.find(normalized_id, "^pref_([%w_]+)$")
      if match ~= nil then
        o[#o+1] = {
          k = key,
          v = device:get_field(name) or value,
        }
      end
    end
  end
  setmetatable(o, {
    __tostring = function (self)
      local str = {}
      for _i,o in pairs(self) do
        str[#str+1] = string.format('<tr><th align="left" style="width:50%%">%s</th><td style="width:50%%">%s</td></tr>', o.k, o.v)
      end
      if #str == 0 then
        str[#str+1] = '<tr><td colspan="2">None</td></tr>'
      end
      return '<table style="font-size:0.6em;min-width:100%%"><tbody>' .. table.concat(str) .. '</tbody></table>'
    end
  })
  return o
end

function utils.load_model_from_json(model, manufacturer)
  local req_loq = string.format("models.%s.%s", model, manufacturer)
  local res = json.decode(require(req_loq))
  
  local o = {
    profiles = res.profiles,
    datapoints = {},
  }
  log.info("Added device", model, manufacturer, #res.datapoints)
  for _p, datapoint in ipairs(res.datapoints) do
    local dpid = tonumber(datapoint.id)
    local base = datapoint.base or {}
    setmetatable(base, {
      __index = {
        group = dpid
      }
    })
    o.datapoints[dpid] = commands[datapoint.command](base)
  end
  
  return o
end

function utils.create_child(driver, device, ngroup, profile)
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

local started_at = os.time()

function utils.details(driver)
  driver:call_on_schedule(60, function()
    local diff = os.difftime(os.time(), started_at)
    -- collectgarbage("collect")
    local memory = math.ceil(collectgarbage("count"))
    print(string.format("start: %s, uptime: %02d:%02d:%02d, memory: %d KB, devices: %d", os.date("%Y-%m-%d %H:%M:%S", started_at), math.floor(diff/3600), math.floor(diff/60), diff % 60, memory, #driver:get_devices()))
  end)
end

return utils