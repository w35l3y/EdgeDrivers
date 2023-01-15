local log = require "log"
local st_utils = require "st.utils"

local zcl_clusters = require "st.zigbee.zcl.clusters"
local commands = require "commands"
local json = require "st.json"

local utils = {}

function utils.is_normal(device)
  --log.info("utils.is_normal", device.profile == device.st_store.profile, st_utils.stringify_table(device.profile, "profile", true))
  local pref = device.preferences.presentation
  return (pref == nil and device.parent_assigned_child_key ~= nil) or (pref ~= nil and pref:find("^normal_") ~= nil)
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
      local output = {}
      for _index, zb_rx in pairs(self) do
        local _data = zb_rx.body.zcl_body.data
        output[#output+1] = string.format('<tr><th align="left">%s</th><td>%d</td><td>%s</td></tr>', _data.type:name(), _data.dpid.value, _data.value.value)
      end
      if #output == 0 then
        output[#output+1] = '<tr><td colspan="3">None</td></tr>'
      end
      return table.concat(output)
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
        <tr><th colspan="3">Datapoints</th></tr>
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
    for name, value in pairs(device.preferences) do
      local normalized_id = st_utils.snake_case(name)
      local match, _length, key = string.find(normalized_id, "^pref_([%w_]+)$")
      if match ~= nil then
        o[key] = device:get_field(name) or value
      end
    end
  end
  setmetatable(o, {
    __tostring = function (self)
      local str = {}
      for k,v in pairs(self) do
        str[#str+1] = string.format('<tr><th align="left" style="width:50%%">%s</th><td style="width:50%%">%s</td></tr>', k, v)
      end
      if #str == 0 then
        str[#str+1] = '<tr><td colspan="2">None</td></tr>'
      end
      return '<table style="font-size:0.6em;min-width:100%%"><tbody>' .. table.concat(str) .. '</tbody></table>'
    end
  })
  return o
end

function utils.load_model_from_json(model)
  local req_loq = string.format("models.%s", model)
  local res = json.decode(require(req_loq))
  
  local o = {}
  for _d, d in ipairs(res.devices) do
    for _m, manufacturer in pairs(d.manufacturers) do
      if o[manufacturer] ~= nil then
        log.warn("Manufacturer overwritten", model, manufacturer)
      end
      o[manufacturer] = {
        profiles = d.profiles,
        datapoints = {},
      }
      log.info("Added device", model, manufacturer, #d.datapoints)
      for _p, datapoint in ipairs(d.datapoints) do
        local dpid = tonumber(datapoint.id)
        local base = datapoint.base or {}
        setmetatable(base, {
          __index = {
            group = dpid
          }
        })
        o[manufacturer].datapoints[dpid] = commands[datapoint.command](base)
      end
    end
  end
  
  return o
end

return utils