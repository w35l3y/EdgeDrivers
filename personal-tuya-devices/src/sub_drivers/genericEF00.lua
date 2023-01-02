--local log = require "log"
--local utils = require "st.utils"

local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zcl_global_commands = require "st.zigbee.zcl.global_commands"

local tuyaEF00_generic_defaults = require "tuyaEF00_generic_defaults"

local NAME = "GenericEF00"

local _boolean = capabilities.switch
local _bitmap = capabilities["valleyboard16460.datapointBitmap"]
local _enum = capabilities["valleyboard16460.datapointEnum"]
local _string = capabilities["valleyboard16460.datapointString"]
local _value = capabilities["valleyboard16460.datapointValue"]
local _raw = capabilities["valleyboard16460.datapointRaw"]

return {
  NAME = NAME,
  can_handle = tuyaEF00_generic_defaults.can_handle,
  supported_capabilities = {
    capabilities.doorControl,
    capabilities.switchLevel,
    _boolean,
    _bitmap,
    _enum,
    _string,
    _value,
    _raw,
  },
  sub_drivers = {
    require "sub_drivers.TS0601",
  },
  lifecycle_handlers = tuyaEF00_generic_defaults.lifecycle_handlers,
  zigbee_handlers = {
    global = {
      [zcl_clusters.TuyaEF00.ID] = {
        [zcl_global_commands.WRITE_ATTRIBUTE_ID] = tuyaEF00_generic_defaults.command_data_report_handler,
      },
    },
    cluster = {
      [zcl_clusters.TuyaEF00.ID] = {
        [zcl_clusters.TuyaEF00.commands.DataReport.ID] = tuyaEF00_generic_defaults.command_data_report_handler,
      }
    },
  },
  capability_handlers = {
    [capabilities.doorControl.ID] = {
      [capabilities.doorControl.commands.open.NAME] = tuyaEF00_generic_defaults.command_true_handler,
      [capabilities.doorControl.commands.close.NAME] = tuyaEF00_generic_defaults.command_false_handler,
    },
    [capabilities.switchLevel.ID] = {
      [capabilities.switchLevel.commands.setLevel.NAME] = tuyaEF00_generic_defaults.command_switchLevel_handler,
    },
    [_boolean.ID] = {
      [_boolean.commands.on.NAME] = tuyaEF00_generic_defaults.command_true_handler,
      [_boolean.commands.off.NAME] = tuyaEF00_generic_defaults.command_false_handler,
    },
    [_bitmap.ID] = {
      [_bitmap.commands.setValue.NAME] = tuyaEF00_generic_defaults.command_bitmap_handler,
    },
    [_enum.ID] = {
      [_enum.commands.setValue.NAME] = tuyaEF00_generic_defaults.command_enum_handler,
    },
    [_string.ID] = {
      [_string.commands.setValue.NAME] = tuyaEF00_generic_defaults.command_string_handler,
    },
    [_value.ID] = {
      [_value.commands.setValue.NAME] = tuyaEF00_generic_defaults.command_value_handler,
    },
    [_raw.ID] = {
      [_raw.commands.setValue.NAME] = tuyaEF00_generic_defaults.command_raw_handler,
    },
  },
}