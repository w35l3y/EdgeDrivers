local attr_mt = {}
attr_mt.__attr_cache = {}
attr_mt.__index = function(self, key)
  if attr_mt.__attr_cache[key] == nil then
    local cluster = rawget(self, "_cluster")
    local req_loc = string.format("st.zigbee.generated.zcl_clusters.%s.server.attributes.%s", cluster.NAME, key)
    local raw_def = require(req_loc)
    raw_def:set_parent_cluster(cluster)
    attr_mt.__attr_cache[key] = raw_def
  end
  return attr_mt.__attr_cache[key]
end

local ServerAttributes = {}

function ServerAttributes:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

setmetatable(ServerAttributes, attr_mt)

return ServerAttributes
