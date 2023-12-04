local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local Int32 = {}
setmetatable(Int32, tuya_types.IntABC.new_mt({ NAME = "Int32", ID = 0x2B }, 4, false))

return Int32
