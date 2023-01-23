-- local log = require "log"
-- local utils = require "st.utils"

local defaults = require "st.zigbee.defaults"
local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local utils = require "st.utils"

local myutils = require "utils"

local profile = "normal_multi_dimmer_v1"
local child_profile = "child-dimmer-v1"
local child_cluster = zcl_clusters.Level

local template = {
  NAME = "GenericDimmer",
  can_handle = function (opts, driver, device, ...)
    return myutils.is_same_profile(device, profile)
          or device.parent_assigned_child_key ~= nil and myutils.is_same_profile(device:get_parent_device(), profile)
  end,
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
  },
  lifecycle_handlers = utils.merge({
    added = function (driver, device, ...)
      local ep_supports_server_cluster = function(cluster_id, ep)
        -- if not ep then return false end
        for _, cluster in ipairs(ep.server_clusters) do
          if cluster == cluster_id then
            return true
          end
        end
        return false
      end
    
      if device.preferences.profile == profile then
        for _, ep in pairs(device.zigbee_endpoints) do
          if ep.id ~= device.fingerprinted_endpoint_id and ep_supports_server_cluster(child_cluster.ID, ep) then
            myutils.create_child(driver, device, ep.id, child_profile)
          end
        end
      end
    end
  }, require "lifecycles"),
}

defaults.register_for_default_handlers(template, template.supported_capabilities)

return template