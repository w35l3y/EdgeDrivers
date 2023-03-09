local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("normal-temphumi-v1.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "_TZE200_znbl8dj5",
      model = "TS0601",
      server_clusters = { 0x0000, 0xEF00 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local test_init_parent = function ()
  utils.send_spell(mock_parent_device)

  test.mock_device.add_test_device(mock_parent_device)
end

test.register_message_test("device_lifecycle added", {
  {
    channel = "device_lifecycle",
    direction = "receive",
    message = { mock_parent_device.id, "added" },
  },
  {
    channel = "zigbee",
    direction = "send",
    message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.McuSyncTime(mock_parent_device) },
  },
  {
    channel = "zigbee",
    direction = "send",
    message = utils.expect_spell(mock_parent_device),
  },
  {
    channel = "device_lifecycle",
    direction = "receive",
    message = { mock_parent_device.id, "init" },
  },
}, {
  test_init = test_init_parent
})

test.register_message_test(
  "infoChanged settings",
  {
    {
      channel = "device_lifecycle",
      direction = "receive",
      message = mock_parent_device:generate_info_changed({
        preferences = {
          profile = "normal_temphumi_v1",
          tempOffset = -2.0,
          humidityOffset = 3.0,
          timezoneOffset = 0,
        }
      })
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 1, tuya_types.Uint32(250)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature(23.0))
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 2, tuya_types.Uint32(75)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.relativeHumidityMeasurement.humidity(78.0))
    },
  }, {
    test_init = test_init_parent
  }
)

-- test.register_message_test(
--   "From zigbee (DP 1) - temperature measurement",
--   {
--     {
--       channel = "zigbee",
--       direction = "receive",
--       message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 1, tuya_types.Uint32(250)) }
--     },
--     {
--       channel = "capability",
--       direction = "send",
--       message = mock_parent_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature(25.0))
--     },
--   }, {
--     test_init = test_init_parent
--   }
-- )

-- test.register_message_test(
--   "From zigbee (DP 2) - relative humidity measurement",
--   {
--     {
--       channel = "zigbee",
--       direction = "receive",
--       message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 2, tuya_types.Uint32(75)) }
--     },
--     {
--       channel = "capability",
--       direction = "send",
--       message = mock_parent_device:generate_test_message("main", capabilities.relativeHumidityMeasurement.humidity(75.0))
--     },
--   }, {
--     test_init = test_init_parent
--   }
-- )