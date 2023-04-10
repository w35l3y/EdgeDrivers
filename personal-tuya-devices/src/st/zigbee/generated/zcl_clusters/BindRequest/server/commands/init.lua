local command_mt = {}
command_mt.__command_cache = {}
command_mt.__index = function(self, key)
  if command_mt.__command_cache[key] == nil then
    local cluster = rawget(self, "_cluster")
    local req_loc = string.format("st.zigbee.generated.zcl_clusters.%s.server.commands.%s", cluster.NAME, key)
    local raw_def = require(req_loc)
    command_mt.__command_cache[key] = raw_def:set_parent_cluster(cluster)
  end
  return command_mt.__command_cache[key]
end

local ServerCommands = {}

function ServerCommands:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

setmetatable(ServerCommands, command_mt)

return ServerCommands
