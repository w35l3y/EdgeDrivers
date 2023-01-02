local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local Uint16 = {}
setmetatable(Uint16, tuya_types.UintABC.new_mt({ NAME = "Uint16", ID = 0x21 }, 2, false))

return Uint16
