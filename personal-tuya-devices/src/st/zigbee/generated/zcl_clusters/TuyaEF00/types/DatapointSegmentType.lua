local data_types = require "st.zigbee.data_types"
local EnumABC = require "st.zigbee.data_types.base_defs.EnumABC"

local DatapointSegmentType = {}
local new_mt = EnumABC.new_mt({NAME = "DatapointSegmentType", ID = data_types.name_to_id_map["Enum8"]}, 1)
new_mt.__index.pretty_print = function(self)
  return string.format("%s: %s", self.NAME or self.field_name, self:name() or string.format("%d", self.value))
end
new_mt.__tostring = new_mt.__index.pretty_print
new_mt.__index.name = function (self)
  local name_lookup = {
    [self.RAW]                                       = "Raw",
    [self.BOOLEAN]                                   = "Boolean",
    [self.VALUE]                                     = "Value",
    [self.STRING]                                    = "String",
    [self.ENUM]                                      = "Enum",
    [self.BITMAP]                                    = "Bitmap",
  }
  return name_lookup[self.value]
end
new_mt.__index.RAW                                       = 0x00
new_mt.__index.BOOLEAN                                   = 0x01
new_mt.__index.VALUE                                     = 0x02
new_mt.__index.STRING                                    = 0x03
new_mt.__index.ENUM                                      = 0x04
new_mt.__index.BITMAP                                    = 0x05
setmetatable(DatapointSegmentType, new_mt)

return DatapointSegmentType
