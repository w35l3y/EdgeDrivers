-- https://developer.smartthings.com/edge-device-drivers/zigbee/driver.html
-- https://developer.tuya.com/en/docs/iot-device-dev/tuya-endtocloud-logic?id=Kav5tfxsbsncf
-- https://raw.githubusercontent.com/kkossev/Hubitat/main/Drivers/Tuya%20Zigbee%20Metering%20Plug/Tuya%20Zigbee%20Metering%20Plug

local log = require "log"
--local st_utils = require "st.utils"

local zb_const = require "st.zigbee.constants"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local defaults = require "st.zigbee.defaults"
--local device_management = require "st.zigbee.device_management"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zcl_global_commands = require "st.zigbee.zcl.global_commands"

local utils = require "utils"

zb_const.ZGP_PROFILE_ID = 0xA1E0

zcl_clusters.green_power_id = 0x0021
zcl_clusters.id_to_name_map[zcl_clusters.green_power_id] = "GreenPowerProxy"

zcl_clusters.tuya_e000_id = 0xE000
zcl_clusters.id_to_name_map[zcl_clusters.tuya_e000_id] = "TuyaE000"
data_types.id_to_name_map[0x48] = "CharString"  -- override Array data type (0xE000 attributes)

zcl_clusters.tuya_e001_id = 0xE001
zcl_clusters.id_to_name_map[zcl_clusters.tuya_e001_id] = "TuyaE001"

zcl_clusters.tuya_ef00_id = 0xEF00
zcl_clusters.id_to_name_map[zcl_clusters.tuya_ef00_id] = "TuyaEF00"

local template = {
  sub_drivers = require "sub_drivers",
  supported_capabilities = {
    capabilities.refresh,
  },
  zigbee_handlers = {
    attr = {
      [zcl_clusters.Basic.ID] = {
        [zcl_clusters.Basic.attributes.ZCLVersion.ID] = function() end,
      },
    },
  },
  health_check = true,
  additional_zcl_profiles = {
    [zb_const.ZGP_PROFILE_ID] = true,
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

local driver = require("st.zigbee")("personal-tuya-devices", template)

utils.details(driver)

driver:run()