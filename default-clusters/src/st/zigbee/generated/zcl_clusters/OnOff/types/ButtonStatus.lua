local data_types = require "st.zigbee.data_types"
local EnumABC = require "st.zigbee.data_types.base_defs.EnumABC"

--- @class st.zigbee.zcl.clusters.OnOff.types.ButtonStatus: st.zigbee.data_types.Enum8
--- @alias ButtonStatus
---
--- @field public byte_length number 1
--- @field public PUSHED number 0
--- @field public DOUBLE number 1
--- @field public HELD number 2
local ButtonStatus = {}
local new_mt = EnumABC.new_mt({NAME = "ButtonStatus", ID = data_types.name_to_id_map["Enum8"]}, 1)
new_mt.__index.pretty_print = function(self)
  local name_lookup = {
    [self.PUSHED]   = "PUSHED",
    [self.DOUBLE] = "DOUBLE",
    [self.HELD] = "HELD",
  }
  return string.format("%s: %s", self.NAME or self.field_name, name_lookup[self.value] or string.format("%d", self.value))
end
new_mt.__tostring = new_mt.__index.pretty_print
new_mt.__index.PUSHED = 0x00
new_mt.__index.DOUBLE = 0x01
new_mt.__index.HELD   = 0x02

setmetatable(ButtonStatus, new_mt)

return ButtonStatus
