local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaE000.client.commands.TuyaCommand"

local Generic = {}
function Generic.deserialize (buf)
  return TuyaCommand.deserialize(buf, Generic)
end
setmetatable(Generic, TuyaCommand.new_mt("Generic", 0x0A))
return Generic