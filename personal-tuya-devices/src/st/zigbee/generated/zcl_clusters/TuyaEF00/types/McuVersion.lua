local data_types = require "st.zigbee.data_types"
local BitmapABC = require "st.zigbee.data_types.base_defs.BitmapABC"

local McuVersion = {}
local new_mt = BitmapABC.new_mt({NAME = "McuVersion", ID = data_types.name_to_id_map["Bitmap8"]}, 1)
new_mt.__index.pretty_print = function(self)
  return string.format("%s: %d.%d.%d", self.NAME or self.field_name, (self.value & 0xC0) >> 6, (self.value & 0x30) >> 4, self.value & 0x0F)
end
new_mt.__tostring = new_mt.__index.pretty_print

setmetatable(McuVersion, new_mt)

return McuVersion
