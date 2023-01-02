local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local Bitmap32 = {}
setmetatable(Bitmap32, tuya_types.BitmapABC.new_mt({ NAME = "Bitmap32", ID = 0x1B }, 4, false))

return Bitmap32
