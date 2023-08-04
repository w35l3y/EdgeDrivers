local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.server.commands.TuyaCommand"

local SendData = {}
function SendData.deserialize (buf)
  return TuyaCommand.deserialize(buf, SendData)
end
setmetatable(SendData, TuyaCommand.new_mt("SendData", 0x04))
return SendData