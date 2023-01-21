local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local profile = t_utils.get_profile_definition("switch_v1.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device(
    {
      profile = profile,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "switch",
          model = "switch",
          server_clusters = { 0x0000, 0x0006 },
					client_clusters = { }
        },
      },
      fingerprinted_endpoint_id = 0x01
    }
)

zigbee_test_utils.prepare_zigbee_env_info()

test.set_test_init_function(function ()
  test.mock_device.add_test_device(mock_parent_device)
end)

-- https://github.com/w35l3y/EdgeDrivers/actions/runs/3972658994/jobs/6810761754
test.register_message_test(
  "Reported on off status should be handled: on ep 1",
  {
    -- {
    --   channel = "device_lifecycle",
    --   direction = "receive",
    --   message = { mock_parent_device.id, "init" }
    -- },
    -- {
    --  channel = "zigbee",
    --  direction = "send",
    --  message = { mock_parent_device.id, zigbee_test_utils.build_attribute_read(mock_parent_device, zcl_clusters.Basic.ID, {
    --    data_types.AttributeId(zcl_clusters.Basic.attributes.ManufacturerName.ID),
    --    data_types.AttributeId(zcl_clusters.Basic.attributes.ZCLVersion.ID),
    --    data_types.AttributeId(zcl_clusters.Basic.attributes.ApplicationVersion.ID),
    --    data_types.AttributeId(zcl_clusters.Basic.attributes.ModelIdentifier.ID),
    --    data_types.AttributeId(zcl_clusters.Basic.attributes.PowerSource.ID),
    --    data_types.AttributeId(0xFFFE),
    --  }):to_endpoint(0x01) }
    -- },
    -- {
    --   channel = "capability",
    --   direction = "send",
    --   message = mock_parent_device:generate_test_message("main", capabilities["valleyboard16460.info"].value("A"))
    -- },
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
		-- test_init=function() end,
	}
)

test.run_registered_tests()
