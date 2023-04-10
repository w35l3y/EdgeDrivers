local Cluster = {}

Cluster.ID = 0x8021
Cluster.NAME = "BindRequestResponse"

local cluster_base = require "st.zigbee.cluster_base"
local ClientAttributes = require ("st.zigbee.generated.zcl_clusters." .. Cluster.NAME .. ".client.attributes")
local ServerAttributes = require ("st.zigbee.generated.zcl_clusters." .. Cluster.NAME .. ".server.attributes")
local ClientCommands = require ("st.zigbee.generated.zcl_clusters." .. Cluster.NAME .. ".client.commands")
local ServerCommands = require ("st.zigbee.generated.zcl_clusters." .. Cluster.NAME .. ".server.commands")
local Types = require ("st.zigbee.generated.zcl_clusters." .. Cluster.NAME .. ".types")

Cluster.server = {}
Cluster.client = {}
Cluster.server.attributes = ServerAttributes:set_parent_cluster(Cluster)
Cluster.client.attributes = ClientAttributes:set_parent_cluster(Cluster)
Cluster.server.commands = ServerCommands:set_parent_cluster(Cluster)
Cluster.client.commands = ClientCommands:set_parent_cluster(Cluster)
Cluster.types = Types

function Cluster.attr_id_map()
  return {
  }
end

function Cluster.server_id_map()
  return {
  }
end

function Cluster.client_id_map()
    return {
  }
end

Cluster.attribute_direction_map = {
}
Cluster.command_direction_map = {
}

setmetatable(Cluster, {__index = cluster_base})

-- -- 47.X and above
-- Cluster:init_attributes_table()
-- Cluster:init_commands_table()

return Cluster
