local tuyaEF00_defaults = require "tuyaEF00_defaults"

return {
  ["_TZE200_1n2kyphz"] = {  -- 4 switches
    [1] = tuyaEF00_defaults.on_off,
    [2] = tuyaEF00_defaults.on_off,
    [3] = tuyaEF00_defaults.on_off,
    [4] = tuyaEF00_defaults.on_off,
  },
  ["_TZE200_9mahtqtg"] = {  -- 6 switches
    [1] = tuyaEF00_defaults.on_off,
    [2] = tuyaEF00_defaults.on_off,
    [3] = tuyaEF00_defaults.on_off,
    [4] = tuyaEF00_defaults.on_off,
    [5] = tuyaEF00_defaults.on_off,
    [6] = tuyaEF00_defaults.on_off,
  },
  ["_TZE200_r731zlxk"] = {  -- 6 switches
    [1] = tuyaEF00_defaults.on_off,
    [2] = tuyaEF00_defaults.on_off,
    [3] = tuyaEF00_defaults.on_off,
    [4] = tuyaEF00_defaults.on_off,
    [5] = tuyaEF00_defaults.on_off,
    [6] = tuyaEF00_defaults.on_off,
  },
  ["_TZE200_wfxuhoea"] = {  -- garage door
    [1] = tuyaEF00_defaults.open_close,
    [3] = tuyaEF00_defaults.open_closed,
  },
  ["_TZE200_e3oitdyu"] = {  -- 2 dimmers
    [1] = tuyaEF00_defaults.on_off,
    [2] = tuyaEF00_defaults.level,
    [3] = tuyaEF00_defaults.level,
    [4] = tuyaEF00_defaults.enum,
    [7] = tuyaEF00_defaults.on_off,
    [8] = tuyaEF00_defaults.level,
    [9] = tuyaEF00_defaults.level,
    [10] = tuyaEF00_defaults.enum,
    -- [15] = tuyaEF00_defaults.on_off,
    -- [16] = tuyaEF00_defaults.level,
    -- [17] = tuyaEF00_defaults.level,
    -- [18] = tuyaEF00_defaults.enum,
  },
}

-- https://github.com/zigpy/zha-device-handlers/blob/05ee5195a0f008d06e9bfe56e216178ee5ac959c/zhaquirks/tuya/mcu/__init__.py#L509
--[[
  1,7,15  bool    switch
  2,8,16  value   current level
  3,9,17  value   minimum level
  4,10,18 enum    bulb type
--]]