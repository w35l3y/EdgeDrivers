--local log = require "log"
--local utils = require "st.utils"

local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zcl_global_commands = require "st.zigbee.zcl.global_commands"
local defaults = require "st.zigbee.defaults"
-- local switch_defaults = require "st.zigbee.defaults.switch_defaults"

local tuyaEF00_model_defaults = require "tuyaEF00_model_defaults"

local template = {
  NAME = "Model",
  can_handle = tuyaEF00_model_defaults.can_handle,
  lifecycle_handlers = tuyaEF00_model_defaults.lifecycle_handlers,
  supported_capabilities = {
    capabilities.alarm,
    capabilities.audioMute,
    capabilities.audioVolume,
    -- capabilities.colorControl,
    -- capabilities.colorTemperature,
    capabilities.doorControl,
    capabilities.energyMeter,
    capabilities.keypadInput,
    capabilities.momentary,
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.thermostatCoolingSetpoint,
    capabilities.thermostatHeatingSetpoint,
    capabilities.thermostatMode,
    capabilities.valve,
    capabilities.windowShade,
    capabilities.windowShadeLevel,
    capabilities.windowShadePreset,
    capabilities["valleyboard16460.datapointBitmap"],
    capabilities["valleyboard16460.datapointEnum"],
    capabilities["valleyboard16460.datapointString"],
    capabilities["valleyboard16460.datapointValue"],
    capabilities["valleyboard16460.datapointRaw"],
  },
  zigbee_handlers = {
    global = {
      [zcl_clusters.TuyaEF00.ID] = {
        [zcl_global_commands.WRITE_ATTRIBUTE_ID] = tuyaEF00_model_defaults.command_response_handler,
      },
    },
    cluster = {
      [zcl_clusters.TuyaEF00.ID] = {
        [zcl_clusters.TuyaEF00.commands.DataResponse.ID] = tuyaEF00_model_defaults.command_response_handler,  -- for some reason, buttons use this
        [zcl_clusters.TuyaEF00.commands.DataReport.ID] = tuyaEF00_model_defaults.command_response_handler,
        [zcl_clusters.TuyaEF00.commands.McuSyncTime.ID] = tuyaEF00_model_defaults.command_synctime_handler,
        [zcl_clusters.TuyaEF00.commands.GatewayStatus.ID] = tuyaEF00_model_defaults.command_gatestatus_handler,
      },
    },
    fallback = tuyaEF00_model_defaults.fallback_handler,
  },
}

tuyaEF00_model_defaults.register_for_default_handlers(template, template.supported_capabilities)
defaults.register_for_default_handlers(template, template.supported_capabilities)

return template