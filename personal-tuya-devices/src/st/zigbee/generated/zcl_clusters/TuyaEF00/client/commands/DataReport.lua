local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.client.commands.TuyaCommand"

local DataReport = {}
function DataReport.deserialize (buf)
  return TuyaCommand.deserialize(buf, DataReport)
end
setmetatable(DataReport, TuyaCommand.new_mt("DataReportClient", 0x02))
return DataReport
