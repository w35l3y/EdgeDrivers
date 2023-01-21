local test = require "integration_test"
local clusters = require "st.zigbee.zcl.clusters"
local OnOff = clusters.OnOff
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local cluster_base = require "st.zigbee.cluster_base"
local read_attribute = require "st.zigbee.zcl.global_commands.read_attribute"
local zcl_messages = require "st.zigbee.zcl"
local messages = require "st.zigbee.messages"
local zb_const = require "st.zigbee.constants"

function cluster_base.build_test_read_attributes(device, cluster_id, attr_ids)
  local read_body = read_attribute.ReadAttribute(attr_ids)
  local zclh = zcl_messages.ZclHeader({
    cmd = data_types.ZCLCommandId(read_attribute.ReadAttribute.ID)
  })
  local addrh = messages.AddressHeader(
      zb_const.HUB.ADDR,
      zb_const.HUB.ENDPOINT,
      device:get_short_address(),
      device:get_endpoint(cluster_id.value),
      zb_const.HA_PROFILE_ID,
      cluster_id.value
  )
  local message_body = zcl_messages.ZclMessageBody({
    zcl_header = zclh,
    zcl_body = read_body
  })
  return messages.ZigbeeMessageTx({
    address_header = addrh,
    body = message_body
  })
end

local profile = t_utils.get_profile_definition("switch_v1.yaml")
local mock_parent_device = test.mock_device.build_test_zigbee_device(
    {
      profile = profile,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "switch",
          model = "switch",
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
        direction = "send",
        message = { mock_parent_device.id, cluster_base.build_test_read_attributes(mock_parent_device, data_types.ClusterId(zcl_clusters.Basic.ID), {
          data_types.AttributeId(zcl_clusters.Basic.attributes.ManufacturerName.ID),
          data_types.AttributeId(zcl_clusters.Basic.attributes.ZCLVersion.ID),
          data_types.AttributeId(zcl_clusters.Basic.attributes.ApplicationVersion.ID),
          data_types.AttributeId(zcl_clusters.Basic.attributes.ModelIdentifier.ID),
          data_types.AttributeId(zcl_clusters.Basic.attributes.PowerSource.ID),
          data_types.AttributeId(0xFFFE),
        }):to_endpoint(0x01) }
      },
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