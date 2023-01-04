local log = require "log"
local st_utils = require "st.utils"

local zcl_clusters = require "st.zigbee.zcl.clusters"

local utils = {}

function utils.is_normal(device)
  --log.info("utils.is_normal", device.profile == device.st_store.profile, st_utils.stringify_table(device.profile, "profile", true))
  local pref = device.preferences.presentation
  return pref == nil or pref:find("^normal_") ~= nil
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
  local fid = device.zigbee_endpoints[device.fingerprinted_endpoint_id] or {}
  local _datapoints = datapoints or {}
  setmetatable(_datapoints, {
    __tostring = function (self)
      local output = {}
      for _index, _data in pairs(self) do
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
    device_id = hexa(fid.device_id, 4),
    profile_id = hexa(fid.profile_id, 4),
    server = map(device.zigbee_endpoints, "server_clusters"),
    client = map(device.zigbee_endpoints, "client_clusters"),
    datapoints = _datapoints,
  }
  setmetatable(o, {__tostring = function (self)
    return string.format(
      [[<table style="font-size:0.6em"><tbody>
        <tr><th align="left">Manufacturer</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Model</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Endpoint</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Device ID</th><td colspan="2">%s</td></tr>
        <tr><th align="left">Profile ID</th><td colspan="2">%s</td></tr>
        <tr><th colspan="3">Server Clusters</th></tr>
        %s
        <tr><th colspan="3">Client Clusters</th></tr>
        %s
        <tr><th colspan="3">Datapoints found</th></tr>
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

return utils