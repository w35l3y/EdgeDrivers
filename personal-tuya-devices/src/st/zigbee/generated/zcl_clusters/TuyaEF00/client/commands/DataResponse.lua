local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.client.commands.TuyaCommand"

local DataResponse = {}
setmetatable(DataResponse, TuyaCommand.new_mt("DataResponse", 0x01))
return DataResponse