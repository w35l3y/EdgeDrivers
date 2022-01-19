-- https://developer-preview.smartthings.com/edge-device-drivers/zigbee/driver.html

local log = require('log')
local utils = require('st.utils')
local capabilities = require('st.capabilities')
local zcl_clusters = require("st.zigbee.zcl.clusters")
local zcl_global_commands = require("st.zigbee.zcl.global_commands")
local overridden_defaults = require("overridden_defaults")
--local clusters = require('st.zigbee.zcl.clusters')
--local defaults = require('st.zigbee.defaults')
--local commands = require('commands')

--local zdo_commands = require("st.zigbee.zdo.commands")

-- https://developer-preview.smartthings.com/docs/devices/capabilities/capabilities-reference#healthCheck

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
      },
      -- [zcl_clusters.Diagnostics.ID] = {
      --   [zcl_clusters.Diagnostics.attributes.LastMessageLQI.ID] = function (driver, device, value, zb_rx)
      --     log.info("!!! Diagnostics LastMessageLQI")
      --     log.info(utils.stringify_table(value, "value", true))
      --     device:emit_component_event(device.profile.components.main, value)
      --   end,
      --   [zcl_clusters.Diagnostics.attributes.LastMessageRSSI.ID] = function (driver, device, value, zb_rx)
      --     log.info("!!! Diagnostics LastMessageRSSI")
      --     log.info(utils.stringify_table(value, "value", true))
      --     device:emit_component_event(device.profile.components.main, value)
      --   end
      -- }
    },
    global = { -- ZclGlobalCommandHandler [ st.zigbee.zcl.global_commands.get_command_by_id(command) ]
      [zcl_clusters.OnOff.ID] = {
--        [zcl_global_commands.CONFIGURE_REPORTING_RESPONSE_ID] = function(driver, device, zb_rx)
--          log.info("ConfigureReportingResponse") -- funcionou
--        end,
        [zcl_global_commands.DEFAULT_RESPONSE_ID] = overridden_defaults.default_response_handler
      },
      -- [zcl_clusters.Diagnostics.ID] = {
      --   [zcl_global_commands.DEFAULT_RESPONSE_ID] = function (driver, device, zb_rx)
      --     log.info("!!! Diagnostics DEFAULT_RESPONSE_ID")
      --   end,
      --   [zcl_global_commands.CONFIGURE_REPORTING_RESPONSE_ID] = function (driver, device, zb_rx)
      --     log.info("!!! Diagnostics CONFIGURE_REPORTING_RESPONSE_ID")
      --   end,
      --   [zcl_global_commands.READ_REPORTING_CONFIGURATION_RESPONSE_ID] = function (driver, device, zb_rx)
      --     log.info("!!! Diagnostics READ_REPORTING_CONFIGURATION_RESPONSE_ID")
      --   end
      -- }
    },
--    zdo = { -- undocumented
--      [zdo_commands.BindRequestResponse.ID] = function()
--        log.info("BindRequestResponse") -- funcionou
--      end
--    },
    cluster = { -- ZclClusterCommandHandler [ ((cluster_tab or {}).get_server_command_by_id or function(...) end)(cluster_tab, command) ]
--      [cluster_ID] = { -- undocumented
--        [command_ID] = handler
--      }
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
    },
--    [capabilities.signalStrength.ID] = {
--      {
--        cluster = zcl_clusters.Diagnostics.ID,
--        attribute = zcl_clusters.Diagnostics.attributes.LastMessageLQI.ID,
--        minimum_interval = 0,
--        maximum_interval = 300,
--        data_type = zcl_clusters.Diagnostics.attributes.LastMessageLQI.base_type
--      },
--      {
--        cluster = zcl_clusters.Diagnostics.ID,
--        attribute = zcl_clusters.Diagnostics.attributes.LastMessageRSSI.ID,
--        minimum_interval = 0,
--        maximum_interval = 300,
--        data_type = zcl_clusters.Diagnostics.attributes.LastMessageRSSI.base_type
--      }
--    },
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

--defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)

local Driver = require('st.zigbee')

local driver = Driver("zigbee-smart-plug", driver_template)

driver:run()