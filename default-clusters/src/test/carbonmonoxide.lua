-- package.loaded["integration_test"] = nil
local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = t_utils.get_profile_definition("carbonmonoxide_v1.yaml"),
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "carbonMonoxide",
      model = "carbonMonoxide",
      server_clusters = { 0x0000, 0x040C, 0x0500 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local test_init = function ()
  test.mock_device.add_test_device(mock_parent_device)
end

test.register_coroutine_test("device_lifecycle added", function ()
  test.timer.__create_and_queue_test_time_advance_timer(0, "oneshot")
  test.socket.zigbee:__expect_send({ mock_parent_device.id, zigbee_test_utils.build_attribute_read(mock_parent_device, zcl_clusters.Basic.ID, { 0x0004, 0x0000, 0x0001, 0x0005, 0x0007, 0xFFFE }):to_endpoint(0x01) })
  test.socket.capability:__expect_send(mock_parent_device:generate_test_message("main", capabilities["valleyboard16460.info"].value("<table style=\"font-size:0.6em;min-width:100%\"><tbody>\n        <tr><th align=\"left\" style=\"width:40%\">Manufacturer</th><td colspan=\"2\" style=\"width:60%\">carbonMonoxide</td></tr>\n        <tr><th align=\"left\">Model</th><td colspan=\"2\">carbonMonoxide</td></tr>\n        <tr><th align=\"left\">Endpoint</th><td colspan=\"2\">0x01</td></tr>\n        <tr><th align=\"left\">Device ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th align=\"left\">Profile ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th colspan=\"3\">Server Clusters</th></tr>\n        <tr><th align=\"left\">CarbonMonoxide</th><td>0x040C</td><td>0x01</td></tr><tr><th align=\"left\">IASZone</th><td>0x0500</td><td>0x01</td></tr><tr><th align=\"left\">Basic</th><td>0x0000</td><td>0x01</td></tr>\n        <tr><th colspan=\"3\">Client Clusters</th></tr>\n        <tr><td colspan=\"3\">None</td></tr>\n      </tbody></table>")))

  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "init" })
end, {
  test_init = test_init
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
      message = mock_parent_device:generate_test_message("main", capabilities.carbonMonoxideDetector.carbonMonoxide.detected())
    },
  }, {
    test_init = test_init
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
      message = mock_parent_device:generate_test_message("main", capabilities.carbonMonoxideDetector.carbonMonoxide.clear())
    },
  }, {
    test_init = test_init
  }
)