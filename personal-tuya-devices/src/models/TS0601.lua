local commands = require "commands"

return {
  -- ["_TZE200_9mahtqtg"] = { -- only for testing purposes
    -- [1] = commands.switch({group=1}),
    -- [2] = commands.switchLevel({group=1}),
    -- [3] = commands.enum({group=1}),
    -- [6] = commands.switch({group=2}),
    -- [5] = commands.switchLevel({group=2}),
    -- [4] = commands.enum({group=2}),
    -- [1] = commands.presenceSensor({group=1,name="state"}),
    -- [2] = commands.value({group=2,name="sensitivity"}),
    -- [3] = commands.value({group=3,name="minimum_range"}),
    -- [4] = commands.value({group=4,name="maximum_range"}),
    -- [101] = commands.value({group=5,name="detection_delay"}),
    -- [102] = commands.value({group=6,name="fading_time"}),
    -- [104] = commands.illuminanceMeasurement({group=1,name="illuminance"}),
  -- },
  ["_TZE200_1n2kyphz"] = {  -- 4 switches
  -- https://github.com/zigpy/zha-device-handlers/blob/dev/zhaquirks/tuya/ts0601_switch.py#L492
    [1] = commands.switch({group=1}),
    [2] = commands.switch({group=2}),
    [3] = commands.switch({group=3}),
    [4] = commands.switch({group=4}),
  },
  ["_TZE200_9mahtqtg"] = {  -- 6 switches
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/fc9f0137669abf9f4e61daf20ddb8904b4e56c44/devices/zemismart.js#L237
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/converters/toZigbee.js#L3816
  -- https://github.com/zigpy/zha-device-handlers/blob/b20b34a9201ba9bd793a84a4fe7516a34c28273f/zhaquirks/tuya/ts0601_switch.py#L574
  -- https://github.com/zigpy/zha-device-handlers/blob/b20b34a9201ba9bd793a84a4fe7516a34c28273f/zhaquirks/tuya/ts0601_switch.py#L656
    [1] = commands.switch({group=1,name="switch1"}),
    [2] = commands.switch({group=2,name="switch2"}),
    [3] = commands.switch({group=3,name="switch3"}),
    [4] = commands.switch({group=4,name="switch4"}),
    [5] = commands.switch({group=5,name="switch5"}),
    [6] = commands.switch({group=6,name="switch6"}),
  },
  ["_TZE200_e3oitdyu"] = {  -- 2 dimmers
  -- https://github.com/zigpy/zha-device-handlers/blob/dev/zhaquirks/tuya/ts0601_dimmer.py#L95
  -- https://github.com/zigpy/zha-device-handlers/blob/cec721eceb85fb7c680b6f468c53610b606355d7/zhaquirks/tuya/mcu/__init__.py#L592
    [1] = commands.switch({group=1}),
    [2] = commands.switchLevel({group=1,rate=10}),
    [3] = commands.value({group=1,name="minimum_level1"}),
    [4] = commands.enum({group=1}),
    [7] = commands.switch({group=2}),
    [8] = commands.switchLevel({group=2,rate=10}),
    [9] = commands.value({group=2,name="minimum_level2"}),
    [10] = commands.enum({group=2}),
  },
  ["_TZE200_r731zlxk"] = {  -- 6 switches
    [1] = commands.switch({group=1}),
    [2] = commands.switch({group=2}),
    [3] = commands.switch({group=3}),
    [4] = commands.switch({group=4}),
    [5] = commands.switch({group=5}),
    [6] = commands.switch({group=6}),
  },
  ["_TZE200_wfxuhoea"] = {  -- garage door
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/devices/tuya.js#L3305
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/converters/toZigbee.js#L2560
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/converters/toZigbee.js#L5858
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/lib/tuya.js#L792
    [1] = commands.doorControl({group=1}),
    [3] = commands.contactSensor({group=1}),
  },
  ["_TZE200_ztc6ggyl"] = {  -- presence sensor
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/devices/tuya.js#L3587
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/converters/toZigbee.js#L7005
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/lib/tuya.js#L833
    [1] = commands.presenceSensor({group=1,name="state"}),
    [2] = commands.value({group=2,name="sensitivity"}),
    [3] = commands.value({group=3,name="minimum_range"}),
    [4] = commands.value({group=4,name="maximum_range"}),
    [101] = commands.value({group=5,name="detection_delay"}),
    [102] = commands.value({group=6,name="fading_time"}),
    [104] = commands.illuminanceMeasurement({group=1,name="illuminance"}),
  },
  ["_TZE204_ztc6ggyl"] = {  -- presence sensor
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/devices/tuya.js#L3587
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/converters/toZigbee.js#L7005
  -- https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/lib/tuya.js#L833
    [1] = commands.presenceSensor({group=1,name="state"}),
    [2] = commands.value({group=2,name="sensitivity"}),
    [3] = commands.value({group=3,name="minimum_range"}),
    [4] = commands.value({group=4,name="maximum_range"}),
    [101] = commands.value({group=5,name="detection_delay"}),
    [102] = commands.value({group=6,name="fading_time"}),
    [104] = commands.illuminanceMeasurement({group=1,name="illuminance"}),
  },
}
