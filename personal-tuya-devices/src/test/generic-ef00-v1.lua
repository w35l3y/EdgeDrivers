local test = require "integration_test"
local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local t_utils = require "integration_test.utils"

local generic_body = require "st.zigbee.generic_body"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local profile = t_utils.get_profile_definition("generic-ef00-v1.yaml")

test.load_all_caps_from_profile(profile)

local mock_parent_device = test.mock_device.build_test_zigbee_device({
  profile = profile,
  zigbee_endpoints = {
    [1] = {
      id = 1,
      manufacturer = "_UNKNOWN_DEVICE",
      model = "TS0601",
      server_clusters = { 0x0000, 0xEF00 },
      client_clusters = { }
    },
  },
  fingerprinted_endpoint_id = 0x01
})

local mock_child_1 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-switch-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 1)
})

local mock_child_2 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-switchLevel-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 2)
})

local mock_child_3 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-airQualitySensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 3)
})

local mock_child_4 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-button-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 4)
})

local mock_child_5 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-carbonDioxideMeasurement-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 5)
})

local mock_child_6 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-contactSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 6)
})

local mock_child_7 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-doorControl-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 7)
})

local mock_child_8 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-dustSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 8)
})

local mock_child_9 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-fineDustSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 9)
})

local mock_child_10 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-veryFineDustSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 10)
})

local mock_child_11 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-formaldehydeMeasurement-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 11)
})

local mock_child_12 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-relativeHumidityMeasurement-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 12)
})

local mock_child_13 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-illuminanceMeasurement-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 13)
})

local mock_child_14 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-motionSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 14)
})

local mock_child_15 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-occupancySensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 15)
})

local mock_child_16 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-presenceSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 16)
})

local mock_child_17 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-temperatureMeasurement-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 17)
})

local mock_child_18 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-tvocMeasurement-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 18)
})

local mock_child_19 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-valve-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 19)
})

local mock_child_20 = test.mock_device.build_test_child_device({
  profile = t_utils.get_profile_definition("child-waterSensor-v1.yaml"),
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 20)
})

local profile_enum = t_utils.get_profile_definition("child-enum-v1.yaml")
test.load_all_caps_from_profile(profile_enum)

local mock_child_21 = test.mock_device.build_test_child_device({
  profile = profile_enum,
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 21)
})

local profile_value = t_utils.get_profile_definition("child-value-v1.yaml")
test.load_all_caps_from_profile(profile_value)

local mock_child_22 = test.mock_device.build_test_child_device({
  profile = profile_value,
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 22)
})

local profile_string = t_utils.get_profile_definition("child-string-v1.yaml")
test.load_all_caps_from_profile(profile_string)

local mock_child_23 = test.mock_device.build_test_child_device({
  profile = profile_string,
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 23)
})

local profile_bitmap = t_utils.get_profile_definition("child-bitmap-v1.yaml")
test.load_all_caps_from_profile(profile_bitmap)

local mock_child_24 = test.mock_device.build_test_child_device({
  profile = profile_bitmap,
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 24)
})

local profile_raw = t_utils.get_profile_definition("child-raw-v1.yaml")
test.load_all_caps_from_profile(profile_raw)

local mock_child_25 = test.mock_device.build_test_child_device({
  profile = profile_raw,
  parent_device_id = mock_parent_device.id,
  parent_assigned_child_key = string.format("%02X", 25)
})

local test_init = function ()
  test.mock_device.add_test_device(mock_parent_device)

  test.socket.device_lifecycle:__queue_receive(mock_parent_device:generate_info_changed({
    preferences = {
      profile = "generic_ef00_v1",
      updateInfo = false,
      switchDatapoints = "1",
      switchLevelDatapoints = "2",
      airQualitySensDatapoints = "3",
      buttonDatapoints = "4",
      carbonDioxideMDatapoints = "5",
      contactSensorDatapoints = "6",
      doorControlDatapoints = "7",
      dustSensorDatapoints = "8",
      fineDustSensorDatapoints = "9",
      veryFineDustSeDatapoints = "10",
      formaldehydeMeDatapoints = "11",
      humidityMeasurDatapoints = "12",
      illuminanceMeaDatapoints = "13",
      motionSensorDatapoints = "14",
      occupancySensoDatapoints = "15",
      presenceSensorDatapoints = "16",
      temperatureMeaDatapoints = "17",
      tvocMeasuremenDatapoints = "18",
      valveDatapoints = "19",
      waterSensorDatapoints = "20",
      enumerationDatapoints = "21",
      valueDatapoints = "22",
      stringDatapoints = "23",
      bitmapDatapoints = "24",
      rawDatapoints = "25",
    }
  }))

  test.mock_device.add_test_device(mock_child_1)
  test.mock_device.add_test_device(mock_child_2)
  test.mock_device.add_test_device(mock_child_3)
  test.mock_device.add_test_device(mock_child_4)
  test.mock_device.add_test_device(mock_child_5)
  test.mock_device.add_test_device(mock_child_6)
  test.mock_device.add_test_device(mock_child_7)
  test.mock_device.add_test_device(mock_child_8)
  test.mock_device.add_test_device(mock_child_9)
  test.mock_device.add_test_device(mock_child_10)
  test.mock_device.add_test_device(mock_child_11)
  test.mock_device.add_test_device(mock_child_12)
  test.mock_device.add_test_device(mock_child_13)
  test.mock_device.add_test_device(mock_child_14)
  test.mock_device.add_test_device(mock_child_15)
  test.mock_device.add_test_device(mock_child_16)
  test.mock_device.add_test_device(mock_child_17)
  test.mock_device.add_test_device(mock_child_18)
  test.mock_device.add_test_device(mock_child_19)
  test.mock_device.add_test_device(mock_child_20)
  test.mock_device.add_test_device(mock_child_21)
  test.mock_device.add_test_device(mock_child_22)
  test.mock_device.add_test_device(mock_child_23)
  test.mock_device.add_test_device(mock_child_24)
  test.mock_device.add_test_device(mock_child_25)
end

test.register_coroutine_test("device_lifecycle added", function ()
  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "added" })

  test.timer.__create_and_queue_test_time_advance_timer(0, "oneshot")
  test.socket.zigbee:__expect_send({ mock_parent_device.id, zigbee_test_utils.build_attribute_read(mock_parent_device, zcl_clusters.Basic.ID, { 0x0004, 0x0000, 0x0001, 0x0005, 0x0007, 0xFFFE }):to_endpoint(0x01) })
  test.timer.__create_and_queue_test_time_advance_timer(0, "oneshot")
  test.socket.capability:__expect_send(mock_parent_device:generate_test_message("main", capabilities["valleyboard16460.info"].value("<table style=\"font-size:0.6em;min-width:100%\"><tbody>\n        <tr><th align=\"left\" style=\"width:40%\">Manufacturer</th><td colspan=\"2\" style=\"width:60%\">_UNKNOWN_DEVICE</td></tr>\n        <tr><th align=\"left\">Model</th><td colspan=\"2\">TS0601</td></tr>\n        <tr><th align=\"left\">Endpoint</th><td colspan=\"2\">0x01</td></tr>\n        <tr><th align=\"left\">Device ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th align=\"left\">Profile ID</th><td colspan=\"2\">0x0000</td></tr>\n        <tr><th colspan=\"3\">Server Clusters</th></tr>\n        <tr><th align=\"left\">Basic</th><td>0x0000</td><td>0x01</td></tr><tr><th align=\"left\">TuyaEF00</th><td>0xEF00</td><td>0x01</td></tr>\n        <tr><th colspan=\"3\">Client Clusters</th></tr>\n        <tr><td colspan=\"3\">None</td></tr>\n        \n      </tbody></table>")))

  test.socket.device_lifecycle:__queue_receive({ mock_parent_device.id, "init" })
end, {
  test_init = function()
    test.mock_device.add_test_device(mock_parent_device)
  end
})

test.register_message_test(
  "switch",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_1.id, { capability = "switch", component = "main", command = "on", args = {} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 1, data_types.Boolean(true)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 1, data_types.Boolean(false)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_1:generate_test_message("main", capabilities.switch.switch("off"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "switchLevel",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_2.id, { capability = "switchLevel", component = "main", command = "setLevel", args = {50} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 2, tuya_types.Uint32(50)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 2, tuya_types.Uint32(30)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_2:generate_test_message("main", capabilities.switchLevel.level(30))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "airQualitySensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 3, tuya_types.Uint32(50)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_3:generate_test_message("main", capabilities.airQualitySensor.airQuality(50.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "button",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 4, tuya_types.Uint32(2)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_4:generate_test_message("main", capabilities.button.button("held"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "carbonDioxideMeasurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 5, tuya_types.Uint32(12)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_5:generate_test_message("main", capabilities.carbonDioxideMeasurement.carbonDioxide(12.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "contactSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 6, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_6:generate_test_message("main", capabilities.contactSensor.contact("open"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "doorControl",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_7.id, { capability = "doorControl", component = "main", command = "open", args = {} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 7, data_types.Boolean(true)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 7, data_types.Boolean(false)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_7:generate_test_message("main", capabilities.doorControl.door("closed"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "dustSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 8, tuya_types.Uint32(20)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_8:generate_test_message("main", capabilities.dustSensor.dustLevel(20.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "fineDustSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 9, tuya_types.Uint32(20)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_9:generate_test_message("main", capabilities.fineDustSensor.fineDustLevel(20.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "veryFineDustSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 10, tuya_types.Uint32(20)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_10:generate_test_message("main", capabilities.veryFineDustSensor.veryFineDustLevel(20.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "formaldehydeMeasurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 11, tuya_types.Uint32(2000)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_11:generate_test_message("main", capabilities.formaldehydeMeasurement.formaldehydeLevel(20.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "relativeHumidityMeasurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 12, tuya_types.Uint32(20)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_12:generate_test_message("main", capabilities.relativeHumidityMeasurement.humidity(20.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "illuminanceMeasurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 13, tuya_types.Uint32(20)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_13:generate_test_message("main", capabilities.illuminanceMeasurement.illuminance(1016))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "motionSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 14, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_14:generate_test_message("main", capabilities.motionSensor.motion("active"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "occupancySensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 15, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_15:generate_test_message("main", capabilities.occupancySensor.occupancy("occupied"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "presenceSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 16, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_16:generate_test_message("main", capabilities.presenceSensor.presence("present"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "temperatureMeasurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 17, tuya_types.Uint32(23)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_17:generate_test_message("main", capabilities.temperatureMeasurement.temperature(23.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "tvocMeasurement",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 18, tuya_types.Uint32(2300)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_18:generate_test_message("main", capabilities.tvocMeasurement.tvocLevel(23.0))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "valve",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_19.id, { capability = "valve", component = "main", command = "open", args = {} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 19, data_types.Boolean(true)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 19, data_types.Boolean(true)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_19:generate_test_message("main", capabilities.valve.valve("open"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "waterSensor",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 20, data_types.Enum8(1)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_20:generate_test_message("main", capabilities.waterSensor.water("wet"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "enum",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_21.id, { capability = "valleyboard16460.datapointEnum", component = "main", command = "setValue", args = {9} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 21, data_types.Enum8(9)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 21, data_types.Enum8(4)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_21:generate_test_message("main", capabilities["valleyboard16460.datapointEnum"].value(4))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "value",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_22.id, { capability = "valleyboard16460.datapointValue", component = "main", command = "setValue", args = {14} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 22, tuya_types.Uint32(14)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 22, tuya_types.Uint32(4)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_22:generate_test_message("main", capabilities["valleyboard16460.datapointValue"].value(4))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "string",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_23.id, { capability = "valleyboard16460.datapointString", component = "main", command = "setValue", args = {"w35l3y"} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 23, data_types.CharString("w35l3y")) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 23, data_types.CharString("w35l3y")) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_23:generate_test_message("main", capabilities["valleyboard16460.datapointString"].value("w35l3y"))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "bitmap 8",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_24.id, { capability = "valleyboard16460.datapointBitmap", component = "main", command = "setValue", args = {0x11} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 24, data_types.Bitmap8(0x11)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 24, data_types.Bitmap8(0x10)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_24:generate_test_message("main", capabilities["valleyboard16460.datapointBitmap"].value(0x10))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "bitmap 16",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_24.id, { capability = "valleyboard16460.datapointBitmap", component = "main", command = "setValue", args = {0x1011} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 24, tuya_types.Bitmap16(0x1011)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 24, tuya_types.Bitmap16(0x1010)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_24:generate_test_message("main", capabilities["valleyboard16460.datapointBitmap"].value(0x1010))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "bitmap 32",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_24.id, { capability = "valleyboard16460.datapointBitmap", component = "main", command = "setValue", args = {0x101011} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 24, tuya_types.Bitmap32(0x101011)) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 24, tuya_types.Bitmap32(0x101010)) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_24:generate_test_message("main", capabilities["valleyboard16460.datapointBitmap"].value(0x101010))
    },
  }, {
    test_init = test_init
  }
)

test.register_message_test(
  "raw",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_child_25.id, { capability = "valleyboard16460.datapointRaw", component = "main", command = "setValue", args = {"w35l3y"} } }
    },
    {
      channel = "zigbee",
      direction = "send",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataRequest(mock_parent_device, 25, generic_body.GenericBody("w35l3y")) }
    },
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_parent_device.id, zcl_clusters.TuyaEF00.commands.DataReport:build_test_rx(mock_parent_device, 25, generic_body.GenericBody("w35l3y")) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_child_25:generate_test_message("main", capabilities["valleyboard16460.datapointRaw"].value("w35l3y"))
    },
  }, {
    test_init = test_init
  }
)
