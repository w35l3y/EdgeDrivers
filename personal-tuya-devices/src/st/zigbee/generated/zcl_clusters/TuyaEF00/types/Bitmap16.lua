local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"

local Bitmap16 = {}
setmetatable(Bitmap16, tuya_types.BitmapABC.new_mt({ NAME = "Bitmap16", ID = 0x19 }, 2, false))

return Bitmap16
