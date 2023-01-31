local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("normal-thermostat-v1.yaml")

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

local test_init = function ()
  test.mock_device.add_test_device(mock_parent_device)
end

test.register_coroutine_test("device_lifecycle added", function ()
  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "added" })

  test.timer.__create_and_queue_test_time_advance_timer(0, "oneshot")
  test.socket.zigbee:__expect_send({ mock_parent_device.id, zigbee_test_utils.build_attribute_read(mock_parent_device, zcl_clusters.Basic.ID, { 0x0004, 0x0000, 0x0001, 0x0005, 0x0007, 0xFFFE }):to_endpoint(0x01) })
  -- test.timer.__create_and_queue_test_time_advance_timer(0, "oneshot")
  -- test.socket.capability:__expect_send(mock_parent_device:generate_test_message("main", capabilities["valleyboard16460.settings"].value("<table style=\"font-size:0.6em;min-width:100%%\"><tbody><tr><th align=\"left\" style=\"width:50%\">detection_delay</th><td style=\"width:50%\">1</td></tr><tr><th align=\"left\" style=\"width:50%\">fading_time</th><td style=\"width:50%\">1500</td></tr><tr><th align=\"left\" style=\"width:50%\">far_detection</th><td style=\"width:50%\">95</td></tr><tr><th align=\"left\" style=\"width:50%\">near_detection</th><td style=\"width:50%\">0</td></tr><tr><th align=\"left\" style=\"width:50%\">sensitivity</th><td style=\"width:50%\">7</td></tr></tbody></table>")))

  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "init" })
end, {
  test_init = function()
    test.mock_device.add_test_device(mock_parent_device)
  end
})

test.register_message_test(
  "infoChanged settings",
  {
    {
      channel = "device_lifecycle",
      direction = "receive",
      message = mock_parent_device:generate_info_changed({
        preferences = {
          profile = "normal_thermostat_v1",
          tempOffset = -2.0,
          humidityOffset = 3.0,
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
    test_init = test_init
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
--     test_init = test_init
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
--     test_init = test_init
--   }
-- )