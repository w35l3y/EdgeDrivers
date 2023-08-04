local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.server.commands.TuyaCommand"

local StatusReportAlt = {}
function StatusReportAlt.deserialize (buf)
  return TuyaCommand.deserialize(buf, StatusReportAlt)
end
setmetatable(StatusReportAlt, TuyaCommand.new_mt("StatusReportAltServer", 0x05))
return StatusReportAlt