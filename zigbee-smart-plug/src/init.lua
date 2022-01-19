-- https://developer-preview.smartthings.com/edge-device-drivers/zigbee/driver.html

local log = require('log')
local utils = require('st.utils')
local capabilities = require('st.capabilities')
local zcl_clusters = require("st.zigbee.zcl.clusters")
local zcl_global_commands = require("st.zigbee.zcl.global_commands")
local overridden_defaults = require("overridden_defaults")

local driver_template = {
  sub_drivers = { require("child") },
  lifecycle_handlers = require('lifecycles'),
  supported_capabilities = {
    capabilities.signalStrength,
    capabilities.refresh,
    capabilities.configuration,
    capabilities.switch,
  },
  zigbee_handlers = {
    attr = {  -- atributos
      [zcl_clusters.OnOff.ID] = {
        [zcl_clusters.OnOff.attributes.OnOff.ID] = overridden_defaults.on_off_attr_handler
      }
    },
    global = { -- ZclGlobalCommandHandler [ st.zigbee.zcl.global_commands.get_command_by_id(command) ]
      [zcl_clusters.OnOff.ID] = {
        [zcl_global_commands.DEFAULT_RESPONSE_ID] = overridden_defaults.default_response_handler
      }
    },
    cluster = { -- ZclClusterCommandHandler [ ((cluster_tab or {}).get_server_command_by_id or function(...) end)(cluster_tab, command) ]
    }
  },
  cluster_configurations = {
    [capabilities.switch.ID] = {
      {
        cluster = zcl_clusters.OnOff.ID,
        attribute = zcl_clusters.OnOff.attributes.OnOff.ID,
        minimum_interval = 0,
        maximum_interval = 300,
        data_type = zcl_clusters.OnOff.attributes.OnOff.base_type
      }
    }
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = overridden_defaults.refresh,
    },
    [capabilities.configuration.ID] = {
      [capabilities.configuration.commands.configure.NAME] = overridden_defaults.configure,
    },
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = overridden_defaults.on,
      [capabilities.switch.commands.off.NAME] = overridden_defaults.off
    }
  }
}

local Driver = require('st.zigbee')

local driver = Driver("zigbee-smart-plug", driver_template)

driver:run()