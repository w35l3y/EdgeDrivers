local cluster_base = require "st.zigbee.cluster_base"
local ClientAttributes = require "st.zigbee.generated.zcl_clusters.TuyaE001.client.attributes" 
local ServerAttributes = require "st.zigbee.generated.zcl_clusters.TuyaE001.server.attributes" 
local ClientCommands = require "st.zigbee.generated.zcl_clusters.TuyaE001.client.commands"
local ServerCommands = require "st.zigbee.generated.zcl_clusters.TuyaE001.server.commands"
local Types = require "st.zigbee.generated.zcl_clusters.TuyaE001.types"

local TuyaE001 = {}
TuyaE001.ID = 0xE001
TuyaE001.NAME = "TuyaE001"
TuyaE001.server = {}
TuyaE001.client = {}
TuyaE001.server.attributes = ServerAttributes:set_parent_cluster(TuyaE001) 
TuyaE001.client.attributes = ClientAttributes:set_parent_cluster(TuyaE001) 
TuyaE001.server.commands = ServerCommands:set_parent_cluster(TuyaE001)
TuyaE001.client.commands = ClientCommands:set_parent_cluster(TuyaE001)
TuyaE001.types = Types
TuyaE001.attr_id_map = {}
TuyaE001.server_id_map = {
}
TuyaE001.client_id_map = {
}
TuyaE001.attribute_direction_map = {
}
TuyaE001.command_direction_map = {
}
TuyaE001.attributes = {}
TuyaE001.commands = {}

function TuyaE001:get_attribute_by_id(attr_id)
  local attr_name = self.attr_id_map[attr_id]
  if attr_name ~= nil then
    return self.attributes[attr_name]
  end
  return nil
end

function TuyaE001:get_server_command_by_id(command_id)
  if self.server_id_map[command_id] ~= nil then
    return self.server.commands[self.server_id_map[command_id]]
  end
  return nil
end

function TuyaE001:get_client_command_by_id(command_id)
  if self.client_id_map[command_id] ~= nil then
    return self.client.commands[self.client_id_map[command_id]]
  end
  return nil
end

local attribute_helper_mt = {}
attribute_helper_mt.__index = function(self, key)
  local direction = TuyaE001.attribute_direction_map[key]
  if direction == nil then
    error(string.format("Referenced unknown attribute %s on cluster %s", key, TuyaE001.NAME))
  end
  return TuyaE001[direction].attributes[key] 
end
setmetatable(TuyaE001.attributes, attribute_helper_mt)

local command_helper_mt = {}
command_helper_mt.__index = function(self, key)
  local direction = TuyaE001.command_direction_map[key]
  if direction == nil then
    error(string.format("Referenced unknown command %s on cluster %s", key, TuyaE001.NAME))
  end
  return TuyaE001[direction].commands[key] 
end
setmetatable(TuyaE001.commands, command_helper_mt)

setmetatable(TuyaE001, {__index = cluster_base})

return TuyaE001
