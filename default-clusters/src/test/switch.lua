local test = require "integration_test"
local clusters = require "st.zigbee.zcl.clusters"
local OnOff = clusters.OnOff
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local profile = t_utils.get_profile_definition("switch_v1.yaml")
local mock_parent_device = test.mock_device.build_test_zigbee_device(
    {
      profile = profile,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "single_switch",
          model = "single_switch",
          server_clusters = { 0x0000, 0x0006 }
        },
      },
      fingerprinted_endpoint_id = 0x01
    }
)


zigbee_test_utils.prepare_zigbee_env_info()

test.set_test_init_function(function ()
  test.mock_device.add_test_device(mock_parent_device)
end)

test.register_message_test(
    "Reported on off status should be handled: on ep 1",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_parent_device.id, OnOff.attributes.OnOff:build_test_attr_report(mock_parent_device,
            true):from_endpoint(0x01) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_parent_device:generate_test_message("main",  capabilities.switch.switch.on())
      }
    }
)

test.run_registered_tests()