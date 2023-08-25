local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.client.commands.TuyaCommand"

local StatusReport = {}
function StatusReport.deserialize (buf)
  return TuyaCommand.deserialize(buf, StatusReport)
end
setmetatable(StatusReport, TuyaCommand.new_mt("StatusReportClient", 0x06))
return StatusReport