local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("normal-multi-dimmer-v2.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "_TZE200_e3oitdyu",
      model = "TS0601",
      server_clusters = { 0x0000, 0xEF00 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local mock_first_child = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-dimmer-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 2)
})

local test_init_parent = function ()
  utils.send_spell(mock_parent_device)

  test.mock_device.add_test_device(mock_parent_device)
end

local test_init = function ()
  test_init_parent()

  test.mock_device.add_test_device(mock_first_child)
end

local test_init_mod = function ()
  test_init_parent()

  test.socket.device_lifecycle:__queue_receive(mock_parent_device:generate_info_changed({preferences = {
    profile = "normal_multi_dimmer_v2",
    rate = 5,
    childDimmerMain02 = false,
    prefMinimumLevel1 = 0,
    prefMinimumLevel2 = 0,
    reverse = true,
  }}))
  test.mock_device.add_test_device(mock_first_child)
  test.socket.device_lifecycle:__queue_receive(mock_first_child:generate_info_changed({preferences = {
    profile = "child_dimmer_v1",
    rate = 5,
    reverse = true,
  }}))
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
    message = utils.expect_settings(mock_parent_device, "<table style=\"font-size:0.6em;min-width:100%\"><tbody><tr><th align=\"left\" style=\"width:50%\">minimum_level1</th><td style=\"width:50%\">0</td></tr><tr><th align=\"left\" style=\"width:50%\">minimum_level2</th><td style=\"width:50%\">0</td></tr></tbody></table>"),
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
    test_init = test_init
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
    test_init = test_init
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
    test_init = test_init
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
    test_init = test_init
  }
)

test.register_message_test(
  "From zigbee (DP 1) - switch (mod)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 1, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.switch.switch.off())
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "To zigbee (DP 1) - switch (mod)",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main", command = "on", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 1, data_types.Boolean(false)) }
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "From zigbee (DP 2) - switch level (mod)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 2, tuya_types.Uint32(500)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main", capabilities.switchLevel.level(100))
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "To zigbee (DP 2) - switch level (mod)",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switchLevel", component = "main", command = "setLevel", args = { 50 } } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 2, tuya_types.Uint32(250)) }
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "From zigbee (DP 7) - switch",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 7, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_first_child:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main02", capabilities.switch.switch.on())
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "To zigbee (DP 7) - switch",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main02", command = "on", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 7, data_types.Boolean(true)) }
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "From zigbee (DP 8) - switch level",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 8, tuya_types.Uint32(1000)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_first_child:generate_test_message("main", capabilities.switchLevel.level(100))
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main02", capabilities.switchLevel.level(100))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "To zigbee (DP 8) - switch level",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switchLevel", component = "main02", command = "setLevel", args = { 50 } } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 8, tuya_types.Uint32(500)) }
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "From zigbee (DP 7) - switch (mod)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 7, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_first_child:generate_test_message("main", capabilities.switch.switch.off())
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main02", capabilities.switch.switch.off())
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "To zigbee (DP 7) - switch (mod)",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main02", command = "on", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 7, data_types.Boolean(false)) }
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "From zigbee (DP 8) - switch level (mod)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 8, tuya_types.Uint32(500)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_first_child:generate_test_message("main", capabilities.switchLevel.level(100))
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main02", capabilities.switchLevel.level(100))
    },
  }, {
    test_init = test_init_mod
  }
)

test.register_message_test(
  "To zigbee (DP 8) - switch level (mod)",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switchLevel", component = "main02", command = "setLevel", args = { 50 } } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 8, tuya_types.Uint32(250)) }
    },
  }, {
    test_init = test_init_mod
  }
)
