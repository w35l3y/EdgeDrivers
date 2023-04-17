local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local utils = require "test.utils"

-- local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("normal-multi-switch-v6.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "_TZE200_r731zlxk",
      model = "TS0601",
      server_clusters = { 0x0000, 0xEF00 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local mock_first_child = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-switch-v1.yaml"),
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
    channel = "device_lifecycle",
    direction = "receive",
    message = { mock_parent_device.id, "init" },
  },
}, {
  test_init = test_init_parent
})

test.register_message_test(
  "From zigbee (DP 1)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, { { 1, data_types.Boolean(true) } }) }
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
  "To zigbee (DP 1)",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main", command = "on", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 1, data_types.Boolean(true) } }) }
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "From zigbee (DP 6)",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, { { 6, data_types.Boolean(false) } }) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_parent_device:generate_test_message("main06", capabilities.switch.switch.off())
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "To zigbee (DP 6)",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_parent_device.id, { capability = "switch", component = "main06", command = "off", args = {} } },
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 6, data_types.Boolean(false) } }) }
    },
  }, {
    test_init = test_init
  }
)

test.register_coroutine_test("infoChanged child 02", function ()
  test.socket.device_lifecycle:__queue_receive(mock_parent_device:generate_info_changed({preferences = {
    profile = "normal_multi_switch_v6",
    childSwitchMain02 = true,
    -- childSwitchMain03 = false,
    -- childSwitchMain04 = false,
  }}))

  test.mock_device.add_test_device(mock_first_child)

  -- from parent
  test.socket.capability:__queue_receive({ mock_parent_device.id, { capability = "switch", component = "main02", command = "off", args = {} } })

  test.socket.zigbee:__expect_send({ mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 2, data_types.Boolean(false) } }) })

  -- from child
  test.socket.capability:__queue_receive({ mock_first_child.id, { capability = "switch", component = "main", command = "on", args = {} } })

  test.socket.zigbee:__expect_send({ mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 2, data_types.Boolean(true) } }) })

  -- from device
  test.socket.zigbee:__queue_receive({ mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, { { 2, data_types.Boolean(false) } }) })

  test.socket.capability:__expect_send(mock_first_child:generate_test_message("main", capabilities.switch.switch.off()))

  test.socket.capability:__expect_send(mock_parent_device:generate_test_message("main02", capabilities.switch.switch.off()))
end, {
  test_init = test_init_parent
})

test.register_coroutine_test("infoChanged child 02 - reverse", function ()
  test.socket.device_lifecycle:__queue_receive(mock_parent_device:generate_info_changed({preferences = {
    profile = "normal_multi_switch_v6",
    childSwitchMain02 = true,
    -- childSwitchMain03 = false,
    -- childSwitchMain04 = false,
  }}))

  test.mock_device.add_test_device(mock_first_child)

  test.socket.device_lifecycle:__queue_receive(mock_first_child:generate_info_changed({preferences = {
    reverse = true,
  }}))

  -- from parent
  test.socket.capability:__queue_receive({ mock_parent_device.id, { capability = "switch", component = "main02", command = "off", args = {} } })

  test.socket.zigbee:__expect_send({ mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 2, data_types.Boolean(true) } }) })

  -- from child
  test.socket.capability:__queue_receive({ mock_first_child.id, { capability = "switch", component = "main", command = "on", args = {} } })

  test.socket.zigbee:__expect_send({ mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, { { 2, data_types.Boolean(false) } }) })

  -- from device
  test.socket.zigbee:__queue_receive({ mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, { { 2, data_types.Boolean(false) } }) })

  test.socket.capability:__expect_send(mock_first_child:generate_test_message("main", capabilities.switch.switch.on()))

  test.socket.capability:__expect_send(mock_parent_device:generate_test_message("main02", capabilities.switch.switch.on()))
end, {
  test_init = test_init_parent
})