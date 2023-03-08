local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("normal-single-dimmer-v1.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "_TZE200_dfxkcots",
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
  "From zigbee (DP 1) - switch",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 1, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.switch.switch.on())
    },
  }, {
    test_init = test_init_parent
  }
)

test.register_message_test(
  "To zigbee (DP 1) - switch",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main", command = "on", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 1, data_types.Boolean(true)) }
    },
  }, {
    test_init = test_init_parent
  }
)

test.register_message_test(
  "From zigbee (DP 2) - switch level",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 2, tuya_types.Uint32(1000)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.switchLevel.level(100))
    },
  }, {
    test_init = test_init_parent
  }
)

test.register_message_test(
  "To zigbee (DP 2) - switch level",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switchLevel", component = "main", command = "setLevel", args = { 50 } } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 2, tuya_types.Uint32(500)) }
    },
  }, {
    test_init = test_init_parent
  }
)

-- test.register_message_test(
--   "From zigbee (DP 3) - switch level",
--   {
--     {
--       channel = "zigbee",
--       direction = "receive",
--       message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 3, tuya_types.Uint32(1000)) }
--     },
--     {
--       channel = "capability",
--       direction = "send",
--       message = mock_parent_device:generate_test_message("main02", capabilities.switchLevel.level(100))
--     },
--   }, {
--     test_init = test_init_parent
--   }
-- )

test.register_message_test(
  "To zigbee (DP 3) - switch level",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switchLevel", component = "main02", command = "setLevel", args = { 50 } } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 3, tuya_types.Uint32(500)) }
    },
  }, {
    test_init = test_init_parent
  }
)

