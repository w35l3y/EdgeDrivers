local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.client.commands.TuyaCommand"

local DataResponse = {}
function DataResponse.deserialize (buf)
  return TuyaCommand.deserialize(buf, DataResponse)
end
setmetatable(DataResponse, TuyaCommand.new_mt("DataResponseClient", 0x01))
return DataResponse