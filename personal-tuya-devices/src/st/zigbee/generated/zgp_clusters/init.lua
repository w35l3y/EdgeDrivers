local zgp_clusters = {}

zgp_clusters.green_power_proxy_id                                   = 0x0021

zgp_clusters.cluster_cache = {}

zgp_clusters.id_to_name_map = {
    [zgp_clusters.green_power_proxy_id]                             = "GreenPowerProxy",
}

local zgp_clusters_mt = {}
zgp_clusters_mt.__cluster_cache = {}
zgp_clusters_mt.__index = function(self, key)
  if zgp_clusters_mt.__cluster_cache[key] == nil then
    local req_loq = string.format("st.zigbee.generated.zcl_clusters.%s", key)
    zgp_clusters_mt.__cluster_cache[key] = require(req_loq)
  end
  return zgp_clusters_mt.__cluster_cache[key]
end
setmetatable(zgp_clusters, zgp_clusters_mt)

zgp_clusters.get_cluster_from_id = function(id)
  local cluster_name = zgp_clusters.id_to_name_map[id]
  if cluster_name ~= nil then
    return zgp_clusters[cluster_name]
  end
  return nil
end

return zgp_clusters
