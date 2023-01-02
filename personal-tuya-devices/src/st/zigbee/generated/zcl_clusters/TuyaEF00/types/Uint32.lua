local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local Uint32 = {}
setmetatable(Uint32, tuya_types.UintABC.new_mt({ NAME = "Uint32", ID = 0x23 }, 4, false))

return Uint32
