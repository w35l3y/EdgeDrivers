local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.server.commands.TuyaCommand"

local DataRequest = {}
function DataRequest.deserialize (buf)
  return TuyaCommand.deserialize(buf, DataRequest)
end
setmetatable(DataRequest, TuyaCommand.new_mt("DataRequest", 0x00))
return DataRequest