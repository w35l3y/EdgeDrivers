local cluster_base = require "st.zigbee.cluster_base"
local ClientAttributes = require "st.zigbee.generated.zcl_clusters.TuyaE000.client.attributes" 
local ServerAttributes = require "st.zigbee.generated.zcl_clusters.TuyaE000.server.attributes" 
local ClientCommands = require "st.zigbee.generated.zcl_clusters.TuyaE000.client.commands"
local ServerCommands = require "st.zigbee.generated.zcl_clusters.TuyaE000.server.commands"
local Types = require "st.zigbee.generated.zcl_clusters.TuyaE000.types"

-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-measuring-smart-plug-access-standard?id=K9ik6zvofpzqk
-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-measuring-smart-plug-access-standard?id=K9ik6zvofpzqk#title-25-DP42%20Cycle%20timing
-- https://developer.tuya.com/en/docs/iot/tuya-zigbee-measuring-smart-plug-access-standard?id=K9ik6zvofpzqk#title-26-DP43%20Random%20timing

local TuyaE000 = {}
TuyaE000.ID = 0xE000
TuyaE000.NAME = "TuyaE000"
TuyaE000.server = {}
TuyaE000.client = {}
TuyaE000.server.attributes = ServerAttributes:set_parent_cluster(TuyaE000) 
TuyaE000.client.attributes = ClientAttributes:set_parent_cluster(TuyaE000) 
TuyaE000.server.commands = ServerCommands:set_parent_cluster(TuyaE000)
TuyaE000.client.commands = ClientCommands:set_parent_cluster(TuyaE000)
TuyaE000.types = Types
TuyaE000.attr_id_map = {}
TuyaE000.server_id_map = {
  [0x0A] = "Generic",
  -- [0x00] = "DataRequest",
  -- [0x02] = "DataReport",  -- GenericBody:  00 1A 01 01 00 01 00 / 00 1B 02 01 00 01 01 / 00 1C 03 01 00 01 01 / 00 1D 04 01 00 01 01 / 00 1E 05 01 00 01 01 / 00 1F 06 01 00 01 01
  -- [0x03] = "DataQuery",
  -- [0x10] = "McuVersionRequest",
  -- [0x12] = "McuOtaNotify",
  -- [0x13] = "OtaBlockDataRequest", -- server or client ?
  -- [0x24] = "McuSyncTime",
}
TuyaE000.client_id_map = {
  [0x0A] = "Generic",
  -- [0x01] = "DataResponse",
  -- [0x02] = "DataReport",  -- 00 1B 02 01 00 01 01
  -- [0x11] = "McuVersionResponse", -- 02 9C 40
  -- [0x14] = "OtaBlockDataResponse", -- server or client ?
  -- [0x15] = "McuOtaResult",
  -- [0x24] = "McuSyncTime",
}
TuyaE000.attribute_direction_map = {
}
TuyaE000.command_direction_map = {
  ["Generic"] = "server",
  -- ["DataRequest"] = "server",
  -- ["DataResponse"] = "client",
  -- ["DataReport"] = "server",
  -- ["DataQuery"] = "server",
  -- ["McuVersionRequest"] = "server",
  -- ["McuVersionResponse"] = "client",
  -- ["McuOtaNotify"] = "server",
  -- ["OtaBlockDataRequest"] = "server",
  -- ["OtaBlockDataResponse"] = "client",
  -- ["McuOtaResult"] = "client",
  -- ["McuSynctime"] = "server",
}
TuyaE000.attributes = {}
TuyaE000.commands = {}

function TuyaE000:get_attribute_by_id(attr_id)
  local attr_name = self.attr_id_map[attr_id]
  if attr_name ~= nil then
    return self.attributes[attr_name]
  end
  return nil
end

function TuyaE000:get_server_command_by_id(command_id)
  if self.server_id_map[command_id] ~= nil then
    return self.server.commands[self.server_id_map[command_id]]
  end
  return nil
end

function TuyaE000:get_client_command_by_id(command_id)
  if self.client_id_map[command_id] ~= nil then
    return self.client.commands[self.client_id_map[command_id]]
  end
  return nil
end

local attribute_helper_mt = {}
attribute_helper_mt.__index = function(self, key)
  local direction = TuyaE000.attribute_direction_map[key]
  if direction == nil then
    error(string.format("Referenced unknown attribute %s on cluster %s", key, TuyaE000.NAME))
  end
  return TuyaE000[direction].attributes[key] 
end
setmetatable(TuyaE000.attributes, attribute_helper_mt)

local command_helper_mt = {}
command_helper_mt.__index = function(self, key)
  local direction = TuyaE000.command_direction_map[key]
  if direction == nil then
    error(string.format("Referenced unknown command %s on cluster %s", key, TuyaE000.NAME))
  end
  return TuyaE000[direction].commands[key] 
end
setmetatable(TuyaE000.commands, command_helper_mt)

setmetatable(TuyaE000, {__index = cluster_base})

return TuyaE000
