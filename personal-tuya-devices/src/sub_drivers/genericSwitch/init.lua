-- local log = require "log"
-- local utils = require "st.utils"

local defaults = require "st.zigbee.defaults"
local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local utils = require "st.utils"

local myutils = require "utils"

local global_profile = "normal_multi_switch_v1"
local child_profile = "child-switch-v1"
local child_cluster = zcl_clusters.OnOff

local ep_supports_server_cluster = function(cluster_id, ep)
  -- if not ep then return false end
  for _, cluster in ipairs(ep.server_clusters) do
    if cluster == cluster_id then
      return true
    end
  end
  return false
end

local create_child_devices = function (driver, device, ...)
  if device.preferences.profile == global_profile then
    for _, ep in pairs(device.zigbee_endpoints) do
      if ep.id ~= device.fingerprinted_endpoint_id and ep_supports_server_cluster(child_cluster.ID, ep) then
        myutils.create_child(driver, device, ep.id, child_profile)
      end
    end
  end
end

local template = {
  NAME = "GenericSwitch",
  can_handle = function (opts, driver, device, ...)
    return myutils.is_profile(device, global_profile)
  end,
  supported_capabilities = {
    capabilities.switch,
  },
  lifecycle_handlers = utils.merge({
    infoChanged = function (driver, device, event, args)
      if args.old_st_store.preferences.profile ~= device.preferences.profile or (not myutils.is_normal(device) and device.profile.components.main == nil) then
        device:try_update_metadata({
          profile = device.preferences.profile:gsub("_", "-")
        })
      end

      create_child_devices(driver, device, event, args)
    end,
    added = create_child_devices
  }, require "lifecycles"),
}

defaults.register_for_default_handlers(template, template.supported_capabilities)

return template