local cluster_base = require "st.zigbee.generated.zgp_clusters.cluster_base"
local ClientAttributes = require "st.zigbee.generated.zcl_clusters.GreenPowerProxy.client.attributes" 
local ServerAttributes = require "st.zigbee.generated.zcl_clusters.GreenPowerProxy.server.attributes" 
local ClientCommands = require "st.zigbee.generated.zcl_clusters.GreenPowerProxy.client.commands"
local ServerCommands = require "st.zigbee.generated.zcl_clusters.GreenPowerProxy.server.commands"
local Types = require "st.zigbee.generated.zcl_clusters.GreenPowerProxy.types"

-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-universal-docking-access-standard?id=K9ik6zvofpzql#subtitle-6-Private%20command%20ID
-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-universal-docking-access-standard?id=K9ik6zvofpzql#title-3-Clusters%2C%20attributes%2C%20and%20commands
-- https://github.com/zigbeefordomoticz/wiki/blob/master/en-eng/Technical/Tuya-0xEF00.md
-- https://github.com/Koenkk/zigbee-herdsman/blob/master/src/zcl/definition/cluster.ts

local GreenPowerProxy = {}
GreenPowerProxy.ID = 0x0021
GreenPowerProxy.NAME = "GreenPowerProxy"
GreenPowerProxy.server = {}
GreenPowerProxy.client = {}
GreenPowerProxy.server.attributes = ServerAttributes:set_parent_cluster(GreenPowerProxy) 
GreenPowerProxy.client.attributes = ClientAttributes:set_parent_cluster(GreenPowerProxy) 
GreenPowerProxy.server.commands = ServerCommands:set_parent_cluster(GreenPowerProxy)
GreenPowerProxy.client.commands = ClientCommands:set_parent_cluster(GreenPowerProxy)
GreenPowerProxy.types = Types
GreenPowerProxy.attr_id_map = {}
GreenPowerProxy.server_id_map = {
--  [0x00] = "DataRequest",
--  [0x02] = "DataReport",  -- GenericBody:  00 1A 01 01 00 01 00 / 00 1B 02 01 00 01 01 / 00 1C 03 01 00 01 01 / 00 1D 04 01 00 01 01 / 00 1E 05 01 00 01 01 / 00 1F 06 01 00 01 01
--  [0x03] = "DataQuery",
--  [0x10] = "McuVersionRequest",
--  [0x12] = "McuOtaNotify",
--  [0x13] = "OtaBlockDataRequest", -- server or client ?
--  [0x24] = "McuSyncTime",
}
GreenPowerProxy.client_id_map = {
--  [0x01] = "DataResponse",
--  [0x02] = "DataReport",  -- 00 1B 02 01 00 01 01
--  [0x11] = "McuVersionResponse", -- 02 9C 40
--  [0x14] = "OtaBlockDataResponse", -- server or client ?
--  [0x15] = "McuOtaResult",
--  [0x24] = "McuSyncTime",
}
GreenPowerProxy.attribute_direction_map = {
}
GreenPowerProxy.command_direction_map = {
--  ["DataRequest"] = "server",
--  ["DataResponse"] = "client",
--  ["DataReport"] = "server",
--  ["DataQuery"] = "server",
--  ["McuVersionRequest"] = "server",
--  ["McuVersionResponse"] = "client",
--  ["McuOtaNotify"] = "server",
--  ["OtaBlockDataRequest"] = "server",
--  ["OtaBlockDataResponse"] = "client",
--  ["McuOtaResult"] = "client",
--  ["McuSynctime"] = "server",
}
GreenPowerProxy.attributes = {}
GreenPowerProxy.commands = {}

function GreenPowerProxy:get_attribute_by_id(attr_id)
  local attr_name = self.attr_id_map[attr_id]
  if attr_name then
    return self.attributes[attr_name]
  end
  return nil
end

function GreenPowerProxy:get_server_command_by_id(command_id)
  if self.server_id_map[command_id] then
    return self.server.commands[self.server_id_map[command_id]]
  end
  return nil
end

function GreenPowerProxy:get_client_command_by_id(command_id)
  if self.client_id_map[command_id] then
    return self.client.commands[self.client_id_map[command_id]]
  end
  return nil
end

local attribute_helper_mt = {}
attribute_helper_mt.__index = function(self, key)
  local direction = GreenPowerProxy.attribute_direction_map[key]
  if direction == nil then
    error(string.format("Referenced unknown attribute %s on cluster %s", key, GreenPowerProxy.NAME))
  end
  return GreenPowerProxy[direction].attributes[key] 
end
setmetatable(GreenPowerProxy.attributes, attribute_helper_mt)

local command_helper_mt = {}
command_helper_mt.__index = function(self, key)
  local direction = GreenPowerProxy.command_direction_map[key]
  if direction == nil then
    error(string.format("Referenced unknown command %s on cluster %s", key, GreenPowerProxy.NAME))
  end
  return GreenPowerProxy[direction].commands[key] 
end
setmetatable(GreenPowerProxy.commands, command_helper_mt)

setmetatable(GreenPowerProxy, {__index = cluster_base})

return GreenPowerProxy
