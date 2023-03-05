local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local UtcTime = {}
setmetatable(UtcTime, tuya_types.UintABC.new_mt({ NAME = "UTCTime", ID = 0xE2 }, 4, false))

return UtcTime
