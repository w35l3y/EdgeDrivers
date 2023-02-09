local log = require "log"

local data_types = require "st.zigbee.data_types"
local zb_const = require "st.zigbee.constants"
local zcl_clusters = require "st.zigbee.zcl.clusters"

local capabilities = require "st.capabilities"
local defaults = require "st.zigbee.defaults"
local device_lib = require "st.device"

local utils = require "utils"

zb_const.ZGP_PROFILE_ID = 0xA1E0

zcl_clusters.green_power_id = 0x0021
zcl_clusters.id_to_name_map[zcl_clusters.green_power_id] = "GreenPowerProxy"

zcl_clusters.tuya_e000_id = 0xE000
zcl_clusters.id_to_name_map[zcl_clusters.tuya_e000_id] = "TuyaCommon"
-- data_types.id_to_name_map[0x48] = "CharString"  -- override Array data type (0xE000 attributes)

zcl_clusters.tuya_e001_id = 0xE001
zcl_clusters.id_to_name_map[zcl_clusters.tuya_e001_id] = "TuyaElectrician"

zcl_clusters.tuya_ef00_id = 0xEF00
zcl_clusters.id_to_name_map[zcl_clusters.tuya_ef00_id] = "TuyaGeneral"

local template = {
  supported_capabilities = {
    capabilities["valleyboard16460.info"],
    capabilities.battery,
    capabilities.carbonMonoxideDetector,
    capabilities.colorControl,
    capabilities.colorTemperature,
    capabilities.contactSensor,
    capabilities.energyMeter,
    capabilities.illuminanceMeasurement,
    capabilities.lock,
    capabilities.motionSensor,
    capabilities.occupancySensor,
    capabilities.powerMeter,
    capabilities.powerSource,
    capabilities.relativeHumidityMeasurement,
    capabilities.smokeDetector,
    capabilities.soundSensor,
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.temperatureMeasurement,
    capabilities.thermostatCoolingSetpoint,
    capabilities.thermostatHeatingSetpoint,
    capabilities.valve,
    capabilities.waterSensor,
    capabilities.windowShade,
    capabilities.windowShadeLevel,
    capabilities.signalStrength,
    capabilities.refresh,
  },
  health_check = true,
  additional_zcl_profiles = {
    [zb_const.ZGP_PROFILE_ID] = true,
  },
  attr = {
    [zcl_clusters.Basic.ID] = {
      [zcl_clusters.Basic.attributes.ZCLVersion.ID] = function ()
        local mt = { visibility = { displayed = false } }
        device:emit_event(capabilities.signalStrength.rssi({ value = zb_rx.rssi.value }, mt))
        device:emit_event(capabilities.signalStrength.lqi({ value = zb_rx.lqi.value }, mt))
      end,
    },
  },
  lifecycle_handlers = {
    init = function (driver, device, ...)
      if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
        device:set_find_child(utils.find_child_fn)

        utils.spell_magic_trick(device)
        device:emit_event(capabilities["valleyboard16460.info"].value(tostring(utils.info(device))))
      end
    end,
    added = function (driver, device, ...)
      if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
        local found, result = utils.get_profiles(device, device.fingerprinted_endpoint_id)
        if found and device.preferences.profile ~= result[1].name then
          utils.update_profile(device, result[1].name)
        end
        for _, ep in pairs(device.zigbee_endpoints) do
          if ep.id ~= device.fingerprinted_endpoint_id then
            local found, result = utils.get_profiles(device, ep.id)
            if found then
              utils.create_child(driver, device, ep.id, "child_" .. result[1].name)
            end
          end
        end
      -- else
      --   local found, result = utils.get_profiles(device, tonumber(device.parent_assigned_child_key, 16))
      --   if found then
      --     local child_profile = "child_" .. result[1].name
      --     if child_profile ~= device.preferences.profile then
      --       utils.update_profile(device, child_profile)
      --     end
      --   end
      end
    end,
    infoChanged = function (driver, device, event, args)
      if args.old_st_store.preferences.profile ~= device.preferences.profile then
        utils.update_profile(device, device.preferences.profile)
      end
    end
  },
  cluster_configurations = {
    [capabilities.refresh.ID] = { -- needed to keep device online (it could be any attribute)
      {
        cluster = zcl_clusters.Basic.ID,
        attribute = zcl_clusters.Basic.attributes.ZCLVersion.ID,
        minimum_interval = 0,
        maximum_interval = 300,
        data_type = data_types.Uint8,
        reportable_change = 1,
      },
    },
  },
}

defaults.register_for_default_handlers(template, template.supported_capabilities)

local driver = require("st.zigbee")("default-clusters", template)

utils.details(driver)

driver:run()
