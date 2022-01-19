

local capabilities = require('st.capabilities')
local zcl_clusters = require("st.zigbee.zcl.clusters")
local zcl_global_commands = require("st.zigbee.zcl.global_commands")
local overridden_defaults = require("child.overridden_defaults")

local driver_template = {
  NAME = "child-smart-plug",
  can_handle = function (opts, driver, device, ...)
    return string.find(device.device_network_id, ":") ~= nil
  end,
  sub_drivers = {},
  lifecycle_handlers = require('child.lifecycles'),
  supported_capabilities = {
    capabilities.configuration,
    capabilities.switch,
  },
  zigbee_handlers = {
    attr = {
      [zcl_clusters.OnOff.ID] = {
        [zcl_clusters.OnOff.attributes.OnOff.ID] = overridden_defaults.on_off_attr_handler
      }
    },
    global = {
      [zcl_clusters.OnOff.ID] = {
        [zcl_global_commands.DEFAULT_RESPONSE_ID] = overridden_defaults.default_response_handler
      }
    },
    cluster = {}
  },
  capability_handlers = {
    [capabilities.configuration.ID] = {
      [capabilities.configuration.commands.configure.NAME] = overridden_defaults.configure,
    },
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = overridden_defaults.on,
      [capabilities.switch.commands.off.NAME] = overridden_defaults.off
    }
  },
}

return driver_template