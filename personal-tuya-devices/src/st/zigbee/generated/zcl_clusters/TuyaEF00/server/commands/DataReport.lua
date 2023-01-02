local TuyaCommand = require "st.zigbee.generated.zcl_clusters.TuyaEF00.server.commands.TuyaCommand"

local DataReport = {}
setmetatable(DataReport, TuyaCommand.new_mt("DataReport", 0x02))
return DataReport