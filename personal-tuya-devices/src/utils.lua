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
local generic_body = require "st.zigbee.generic_body"

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

function utils.get_value(data)
  if getmetatable(data) == generic_body.GenericBody then
    return data:_serialize()
  end
  return data.value
end

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
  return (not pref and device.parent_assigned_child_key ~= nil) or (pref and pref:find("^normal_") ~= nil) or false
end

function utils.is_same_profile(device, profile, mfr)
  return device.preferences and ((mfr and mfr == device.preferences.manufacturer) or (device.preferences.profile == profile and not (device.preferences.manufacturer and mfr))) or false
end

function utils.is_profile(device, profile, mfr)
  return device.parent_assigned_child_key and utils.is_same_profile(device:get_parent_device(), profile, mfr) or utils.is_same_profile(device, profile, mfr)
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

function utils.info(device, datapoints)
  local fei = device.zigbee_endpoints[device.fingerprinted_endpoint_id] or device.zigbee_endpoints[tostring(device.fingerprinted_endpoint_id)] or {}
  local _datapoints = datapoints or {}
  setmetatable(_datapoints, {
    __tostring = function (self)
      if datapoints == nil then
        return ""
      end
      local output = {}
      for _index, _data in st_utils.pairs_by_key(self) do
        output[#output+1] = string.format('<tr><th align="left">%s</th><td>%d</td><td>%s</td></tr>', _data.type:name(), _data.dpid.value, st_utils.stringify_table(utils.get_value(_data.value)))
      end
      if #output == 0 then
        output[#output+1] = '<tr><td colspan="3">None</td></tr>'
      end
      if not device:supports_server_cluster(zcl_clusters.tuya_ef00_id) then
        output[#output+1] = '<tr><td colspan="3">Your device didn\'t expose 0xEF00 cluster.</td></tr>'
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
    network_id = "0x" .. device.device_network_id,
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
        <tr><th align="left">Network ID</th><td colspan="2">%s</td></tr>
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
      self.network_id,
      self.profile_id,
      self.server,
      self.client,
      self.datapoints
    )
  end})

  return o
end

function utils.debug(device)
  local p = device:get_field("profile")
  local o = {
    manufacturer = device:get_manufacturer(),
    exposes = map(device.zigbee_endpoints, "server_clusters")[0xEF00],
    default_profile = p == nil,
    profile = p or (device.preferences.profile and device.preferences.profile:gsub("_", "-")),
    expects = device:get_field("expects"),
    default_dp = true,
    mode = "Custom",
  }
  if o.profile == "generic-ef00-v1" then
    o.mode = "Generic"
  elseif o.manufacturer ~= o.expects then
    o.mode = "Similarity"
  end

  for name,value in st_utils.pairs_by_key(device.preferences) do
    local normalized_id = st_utils.snake_case(name)
    -- log.debug(normalized_id, value, type(value))
    local match, _length = string.find(normalized_id, "^dp_[%w_]+_main%x%x$")
    if match and value and value ~= 0 then
      o.default_dp = false
      break
    end
  end

  setmetatable(o, {
    __tostring = function (self)
      return string.format(
        [[<table style="font-size:0.6em;min-width:100%%"><tbody>
        <tr><th align="left" style="width:35%%">Actual</th><td style="width:65%%">%s</td></tr>
        <tr><th align="left">Expected</th><td>%s</td></tr>
        <tr><th align="left">Profile</th><td>%s</td></tr>
        <tr><th align="left">Mode</th><td>%s</td></tr>
        <tr><th align="left">Preferences</th><td>%s</td></tr>
        <tr><th align="left">Exposes EF00</th><td>%s</td></tr>
        <tr><th align="left">Default DP</th><td>%s</td></tr>
        </tbody></table>]],
        self.manufacturer,
        self.expects or "-",
        self.profile or "-",
        self.mode or "-",
        self.default_profile and "Default" or "Modified",
        self.exposes and "Yes" or "No",
        self.default_dp and "Yes" or "No"
      )
    end
  })

  return o
end

function utils.settings(device)
  local o = {}
  if device.preferences then
    for name, value in st_utils.pairs_by_key(device.preferences) do
      local normalized_id = st_utils.snake_case(name)
      local match, _length, key = string.find(normalized_id, "^pref_([%w_]+)$")
      if match then
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
      return '<table style="font-size:0.6em;min-width:100%"><tbody>' .. table.concat(str) .. '</tbody></table>'
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
  log.info("Creating child...", profile, ngroup)
  local group = string.format("%02X", ngroup)
  local label = profile:gsub("v1$", group):gsub("-", " ")
  local created = device:get_child_by_parent_assigned_key(group)
  if not created then
    driver:try_create_device({
      type = "EDGE_CHILD",
      device_network_id = nil,
      parent_assigned_child_key = group,
      label = label,
      profile = profile,
      parent_device_id = device.id,
      manufacturer = driver.NAME,
      model = profile,
      vendor_provided_label = label,
    })
  end
end

local ep_supports_server_cluster = function(cluster_id, ep)
  -- if not ep then return false end
  for _, cluster in ipairs(ep.server_clusters) do
    if cluster == cluster_id then
      return true
    end
  end
  return false
end

function utils.create_child_devices (global_profile, child_profile, child_cluster)
  return function (driver, device, ...)
    if device.preferences.profile == global_profile then
      for _, ep in pairs(device.zigbee_endpoints) do
        if ep.id ~= device.fingerprinted_endpoint_id and ep_supports_server_cluster(child_cluster.ID, ep) then
          utils.create_child(driver, device, ep.id, child_profile)
        end
      end
    end
  end
end

local started_at = os.time()

function utils.details(driver)
  driver:call_on_schedule(60, function()
    local diff = os.difftime(os.time(), started_at)
    -- collectgarbage("collect")
    local memory = math.ceil(collectgarbage("count"))
    print(string.format("start: %s, uptime: %02d:%02d:%02d, memory: %d KB, devices: %d", os.date("%Y-%m-%d %H:%M:%S", started_at), math.floor(diff/3600), math.floor((diff%3600)/60), diff % 60, memory, #driver:get_devices()))
    -- local g = os.time(os.date('!*t'))
    -- print("G", os.date('%c', g), g, string.format("%X", g))
    -- local l = os.time(os.date('*t'))
    -- print("L", os.date('%c', l), l, string.format("%X", l))
  end)
end

return utils