-- package.loaded["integration_test"] = nil
local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = t_utils.get_profile_definition("switch_v1.yaml"),
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "switch",
      model = "switch",
      server_clusters = { 0x0000, 0x0006 },
      client_clusters = { }
    },
    [2] = {
      id = 2,
      manufacturer = "child_switch",
      model = "child_switch",
      server_clusters = { 0x0006 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local mock_first_child = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child_switch_v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 2)
})

local function expect_send_init()
  utils.send_spell(mock_parent_device)
  utils.send_info(mock_parent_device, "<table style=\"font-size:0.6em;min-width:100%\"><tbody>\n        <tr><th align=\"left\" style=\"width:40%\">Manufacturer</th><td colspan=\"2\" style=\"width:60%\">switch</td></tr>\n        <tr><th align=\"left\">Model</th><td colspan=\"2\">switch</td></tr>\n        <tr><th align=\"left\">Endpoint</th><td colspan=\"2\">0x01</td></tr>\n        <tr><th align=\"left\">Device ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th align=\"left\">Network ID</th><td colspan=\"2\">0x0004</td></tr>\n        <tr><th align=\"left\">Profile ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th colspan=\"3\">Server Clusters</th></tr>\n        <tr><th align=\"left\">Basic</th><td>0x0000</td><td>0x01</td></tr><tr><th align=\"left\">OnOff</th><td>0x0006</td><td>0x01, 0x02</td></tr>\n        <tr><th colspan=\"3\">Client Clusters</th></tr>\n        <tr><td colspan=\"3\">None</td></tr>\n      </tbody></table>")
end

local test_init_parent = function ()
  expect_send_init()

  test.mock_device.add_test_device(mock_parent_device)
end

local test_init = function ()
  test_init_parent()

  test.mock_device.add_test_device(mock_first_child)
end

test.register_coroutine_test("device_lifecycle added", function ()
  -- mock_parent_device:expect_metadata_update({profile="switch_v1"})
  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "added" })

  mock_parent_device:expect_device_create({
    type = "EDGE_CHILD",
    -- device_network_id = nil,
    parent_assigned_child_key = "02",
    label = "Child 2",
    profile = "child_switch_v1",
    parent_device_id = mock_parent_device.id,
    manufacturer = "default-clusters",
    model = "child_switch_v1",
    -- vendor_provided_label = "Child 2",
  })

  expect_send_init()

  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "init" })
end, {
  test_init = test_init_parent
})

test.register_message_test(
  "From zigbee",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.OnOff.attributes.OnOff:build_test_attr_report(mock_parent_device,
          true):from_endpoint(0x01) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main",  capabilities.switch.switch.on())
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "To zigbee",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main", command = "on", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.OnOff.commands.On(mock_parent_device) }
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "From zigbee",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.OnOff.attributes.OnOff:build_test_attr_report(mock_parent_device,
          false):from_endpoint(0x02) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_first_child:generate_test_message("main", capabilities.switch.switch.off())
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "To zigbee",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_first_child.id, { capability = "switch", component = "main", command = "off", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.OnOff.commands.Off(mock_parent_device):to_endpoint(0x02) }
    },
  }, {
    test_init = test_init
  }
)
