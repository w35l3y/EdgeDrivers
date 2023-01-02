local tuyaEF00_defaults = require "tuyaEF00_defaults"

return {
  ["_TZE200_1n2kyphz"] = {  -- 4 switches
    [1] = tuyaEF00_defaults.switch,
    [2] = tuyaEF00_defaults.switch,
    [3] = tuyaEF00_defaults.switch,
    [4] = tuyaEF00_defaults.switch,
  },
  ["_TZE200_9mahtqtg"] = {  -- 6 switches
    [1] = tuyaEF00_defaults.switch,
    [2] = tuyaEF00_defaults.switch,
    [3] = tuyaEF00_defaults.switch,
    [4] = tuyaEF00_defaults.switch,
    [5] = tuyaEF00_defaults.switch,
    [6] = tuyaEF00_defaults.switch,
  },
  ["_TZE200_r731zlxk"] = {  -- 6 switches
    [1] = tuyaEF00_defaults.switch,
    [2] = tuyaEF00_defaults.switch,
    [3] = tuyaEF00_defaults.switch,
    [4] = tuyaEF00_defaults.switch,
    [5] = tuyaEF00_defaults.switch,
    [6] = tuyaEF00_defaults.switch,
  },
  ["_TZE200_wfxuhoea"] = {  -- garage door
    [1] = tuyaEF00_defaults.doorControl,
    [3] = tuyaEF00_defaults.contactSensor,
  },
  ["_TZE200_e3oitdyu"] = {  -- 2 dimmers
    [1] = tuyaEF00_defaults.switch,
    [2] = tuyaEF00_defaults.dimmer,
    [3] = tuyaEF00_defaults.dimmer,
    [4] = tuyaEF00_defaults.enum,
    [7] = tuyaEF00_defaults.switch,
    [8] = tuyaEF00_defaults.dimmer,
    [9] = tuyaEF00_defaults.dimmer,
    [10] = tuyaEF00_defaults.enum,
  },
}

-- https://github.com/zigpy/zha-device-handlers/blob/05ee5195a0f008d06e9bfe56e216178ee5ac959c/zhaquirks/tuya/mcu/__init__.py#L509
--[[
  1,7,15  bool    switch
  2,8,16  value   current level
  3,9,17  value   minimum level
  4,10,18 enum    bulb type
--]]