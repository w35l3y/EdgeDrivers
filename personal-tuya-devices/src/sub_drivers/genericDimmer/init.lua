local log = require "log"
-- local utils = require "st.utils"

local defaults = require "st.zigbee.defaults"
local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local utils = require "st.utils"

local myutils = require "utils"

local global_profile = "normal_multi_dimmer_v1"
local child_profile = "child-dimmer-v1"
local child_cluster = zcl_clusters.Level

local create_child_devices = myutils.create_child_devices(global_profile, child_profile, child_cluster)

local constants = {
  FORCE_EF00_CLUSTER = "FORCE_EF00_CLUSTER",
}

local template = {
  NAME = "GenericDimmer",
  can_handle = function (opts, driver, device, ...)
    return myutils.is_profile(device, global_profile)
  end,
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
  },
  lifecycle_handlers = utils.merge({
    infoChanged = function (driver, device, event, args)
      -- if args.old_st_store.preferences.logLevel ~= device.preferences.logLevel then
      --   log.set_log_level(device.preferences.logLevel)
      -- end
      if args.old_st_store.preferences.profile ~= device.preferences.profile or (not myutils.is_normal(device) and device.profile.components.main == nil) then
        log.debug("Profile changed...", args.old_st_store.preferences.profile, device.preferences.profile)
        local p = device.preferences.profile:gsub("_", "-")
        device:set_field("profile", p, { persist = true })
        device:set_field(constants.FORCE_EF00_CLUSTER, true, { persist = true })
        device:try_update_metadata({
          profile = p
        })
      end

      create_child_devices(driver, device, event, args)
    end,
    added = create_child_devices
  }, require "lifecycles"),
}

defaults.register_for_default_handlers(template, template.supported_capabilities)

return template