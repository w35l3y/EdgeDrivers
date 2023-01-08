local tuyaEF00_defaults = require "tuyaEF00_defaults"

return {
  -- ["_TZE200_9mahtqtg"] = {
  --   [1] = tuyaEF00_defaults.switch({group=1}),
  --   [2] = tuyaEF00_defaults.switchLevel({group=1}),
  --   [3] = tuyaEF00_defaults.enum({group=1}),
  --   [6] = tuyaEF00_defaults.switch({group=2}),
  --   [5] = tuyaEF00_defaults.switchLevel({group=2}),
  --   [4] = tuyaEF00_defaults.enum({group=2}),
  -- },
  ["_TZE200_9mahtqtg"] = {  -- 6 switches
    [1] = tuyaEF00_defaults.switch({group=1}),
    [2] = tuyaEF00_defaults.switch({group=2}),
    [3] = tuyaEF00_defaults.switch({group=3}),
    [4] = tuyaEF00_defaults.switch({group=4}),
    [5] = tuyaEF00_defaults.switch({group=5}),
    [6] = tuyaEF00_defaults.switch({group=6}),
  },
  ["_TZE200_1n2kyphz"] = {  -- 4 switches
    [1] = tuyaEF00_defaults.switch({group=1}),
    [2] = tuyaEF00_defaults.switch({group=2}),
    [3] = tuyaEF00_defaults.switch({group=3}),
    [4] = tuyaEF00_defaults.switch({group=4}),
  },
  ["_TZE200_r731zlxk"] = {  -- 6 switches
    [1] = tuyaEF00_defaults.switch({group=1}),
    [2] = tuyaEF00_defaults.switch({group=2}),
    [3] = tuyaEF00_defaults.switch({group=3}),
    [4] = tuyaEF00_defaults.switch({group=4}),
    [5] = tuyaEF00_defaults.switch({group=5}),
    [6] = tuyaEF00_defaults.switch({group=6}),
  },
  ["_TZE200_wfxuhoea"] = {  -- garage door
    [1] = tuyaEF00_defaults.doorControl({group=1}),
    [3] = tuyaEF00_defaults.contactSensor({group=1}),
  },
  ["_TZE200_e3oitdyu"] = {  -- 2 dimmers
    [1] = tuyaEF00_defaults.switch({group=1}),
    [2] = tuyaEF00_defaults.switchLevel({group=1,divider=10}),
    [4] = tuyaEF00_defaults.enum({group=1}),
    [7] = tuyaEF00_defaults.switch({group=2}),
    [8] = tuyaEF00_defaults.switchLevel({group=2,divider=10}),
    [10] = tuyaEF00_defaults.enum({group=2}),
  },
}

-- https://github.com/zigpy/zha-device-handlers/blob/05ee5195a0f008d06e9bfe56e216178ee5ac959c/zhaquirks/tuya/mcu/__init__.py#L509
--[[
  1,7,15  bool    switch
  2,8,16  value   current level
  3,9,17  value   minimum level
  4,10,18 enum    bulb type
--]]