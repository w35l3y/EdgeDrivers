local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("normal-presenceSensor-v1.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "_TZE200_ztc6ggyl",
      model = "TS0601",
      server_clusters = { 0x0000, 0xEF00 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local test_init = function ()
  utils.send_spell(mock_parent_device)

  test.mock_device.add_test_device(mock_parent_device)
end

test.register_message_test("device_lifecycle added", {
  {
    channel = "device_lifecycle",
    direction = "receive",
    message = { mock_parent_device.id, "added" },
  },
  -- {
  --   channel = "zigbee",
  --   direction = "send",
  --   message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.McuSyncTime(mock_parent_device) },
  -- },
  {
    channel = "zigbee",
    direction = "send",
    message = utils.expect_spell(mock_parent_device),
  },
  {
    channel = "capability",
    direction = "send",
    message = utils.expect_settings(mock_parent_device, '<table style="font-size:0.6em;min-width:100%"><tbody><tr><th align="left" style="width:50%">detection_delay</th><td style="width:50%">1</td></tr><tr><th align="left" style="width:50%">fading_time</th><td style="width:50%">90</td></tr><tr><th align="left" style="width:50%">far_detection</th><td style="width:50%">1000</td></tr><tr><th align="left" style="width:50%">near_detection</th><td style="width:50%">0</td></tr><tr><th align="left" style="width:50%">sensitivity</th><td style="width:50%">7</td></tr></tbody></table>'),
  },
  {
    channel = "device_lifecycle",
    direction = "receive",
    message = { mock_parent_device.id, "init" },
  },
}, {
  test_init = test_init
})

test.register_message_test(
  "From zigbee (DP 1) - presence sensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, { { 1, data_types.Boolean(true) } }) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.presenceSensor.presence.present())
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "From zigbee (DP 104) - illuminance measurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, { { 104, tuya_types.Uint32(234) } }) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.illuminanceMeasurement.illuminance(1822))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "infoChanged settings",
  {
    {
      channel = "device_lifecycle",
      direction = "receive",
      message = mock_parent_device:generate_info_changed({
        preferences = {
          profile = "normal_presenceSensor_v1",
          prefSensitivity = 4,
          prefNearDetection = 15,
          prefFarDetection = 85,
          prefDetectionDelay = 4,
          prefFadingTime = 10,
        }
      })
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 101, tuya_types.Uint32(4) } }) }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 102, tuya_types.Uint32(10) } }) }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 4, tuya_types.Uint32(85) } }) }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 3, tuya_types.Uint32(15) } }) }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 2, tuya_types.Uint32(4) } }) }
    },
  }, {
    test_init = test_init
  }
)