-- package.loaded["integration_test"] = nil
local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

local profile = t_utils.get_profile_definition("sound_v1.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "soundSensor",
      model = "soundSensor",
      server_clusters = { 0x0000, 0x0500 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local INFO = "<table style=\"font-size:0.6em;min-width:100%\"><tbody>\n        <tr><th align=\"left\" style=\"width:40%\">Manufacturer</th><td colspan=\"2\" style=\"width:60%\">soundSensor</td></tr>\n        <tr><th align=\"left\">Model</th><td colspan=\"2\">soundSensor</td></tr>\n        <tr><th align=\"left\">Endpoint</th><td colspan=\"2\">0x01</td></tr>\n        <tr><th align=\"left\">Device ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th align=\"left\">Network ID</th><td colspan=\"2\">0x0001</td></tr>\n        <tr><th align=\"left\">Profile ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th colspan=\"3\">Server Clusters</th></tr>\n        <tr><th align=\"left\">IASZone</th><td>0x0500</td><td>0x01</td></tr><tr><th align=\"left\">Basic</th><td>0x0000</td><td>0x01</td></tr>\n        <tr><th colspan=\"3\">Client Clusters</th></tr>\n        <tr><td colspan=\"3\">None</td></tr>\n      </tbody></table>"

local function expect_send_init()
  utils.send_spell(mock_parent_device)
  utils.send_info(mock_parent_device, INFO)
end

local function test_init_parent()
  expect_send_init()

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
    message = utils.expect_spell(mock_parent_device),
  },
  {
    channel = "capability",
    direction = "send",
    message = utils.expect_info(mock_parent_device, INFO),
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
  "From zigbee (detected)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.IASZone.attributes.ZoneStatus:build_test_attr_report(mock_parent_device,
      0x0001):from_endpoint(0x01) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.soundSensor.sound.detected())
    },
  }, {
    test_init = test_init_parent
  }
)

test.register_message_test(
  "From zigbee (clear)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.IASZone.attributes.ZoneStatus:build_test_attr_report(mock_parent_device,
      0xFFFC):from_endpoint(0x01) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.soundSensor.sound.clear())
    },
  }, {
    test_init = test_init_parent
  }
)